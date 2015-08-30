#!/usr/bin/env ruby

#  Accelerator.rb
#  Accelerator
#
#  Created by John Holdsworth on 30/08/2015.
#  Copyright (c) 2015 John Holdsworth. All rights reserved.

Dir.chdir( File.dirname(__FILE__) )

def patch( path, &patcher )
    print( "Patching #{path}\n" )
    contents = File.open( path, "r" ).read()
    contents = patcher.call( contents )
    File.open( path, "w" ).write( contents )
end

# patch original project to extract list of object files for pods

Dir.glob("../../*.xcodeproj/project.pbxproj").each { |project|
    patch( project ) { |contents|
        contents.sub( /(shellScript = ")(diff \\\"\$\{PODS_ROOT\}\/..\/Podfile.lock\\\")/, '\1# Accelerator patch here...\\nexport EXCLUDED_OBJECTS_PATTERN=\\\"/BIT\\\"\\nls -t \\\"$OBJROOT\\\"/Pods.build/$CONFIGURATION$EFFECTIVE_PLATFORM_NAME/*.build/Objects-normal/$CURRENT_ARCH/*.o | egrep -v \\\"$EXCLUDED_OBJECTS_PATTERN\\\" >\\\"$OBJROOT\\\"/Pods.build/$CONFIGURATION\$EFFECTIVE_PLATFORM_NAME.objects.filelist\\n\2' )
    }
}

# add object file list to OTHER_LDFLAGS

['debug', 'release'].each { |config|
    patch( "../Target Support Files/Pods/Pods.#{config}.xcconfig" ) { |contents|
        contents.sub( /(OTHER_LDFLAGS = .*)/, '\1 -filelist "$(OBJROOT)/Pods.build/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME).objects.filelist"' )
    }
}

# patch pod framework installer to create null pods

patch( "../Target Support Files/Pods/Pods-frameworks.sh" ) { |contents|
    contents = contents.sub( /install_framework\(\)\n/, <<BASH )
install_framework()
{
    local framework=$(basename "$1")
    local source="${BUILT_PRODUCTS_DIR}/Accelerator.framework"
    local destination="${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/${framework}"
    local plist="${destination}/Info.plist"
    local name=${framework%.*}

    if [ ! -f "${destination}/Headers/Accelerator.h" ]; then
        if [ ! -d "${source}" ]; then
            source="${BUILT_PRODUCTS_DIR}/Pods/Accelerator.framework"
        fi

        if [ -L "${source}" ]; then
            echo "Symlinked..."
            source=$(readlink "${source}")
        fi

        rm -rf "${destination}"
        cp -rf "${source}" "${destination}"

        if [ "$name" != "Accelerator" ]; then
            plutil -convert xml1 "${plist}"
            /usr/libexec/PlistBuddy -c "set CFBundleIdentifier org.cocoapods.$name" "${plist}"
            /usr/libexec/PlistBuddy -c "set CFBundleExecutable $name" "${plist}"
            plutil -convert binary1 "${plist}"

            mv "${destination}/Accelerator" "${destination}/$name"
        fi

        if [ "${CODE_SIGNING_REQUIRED}" == "YES" ]; then
        code_sign_if_enabled "${destination}"
        fi
    fi
}

orig_install_framework()
BASH
    if contents !~ /code_sign_if_enabled\(\)/
        contents = contents.gsub( /code_sign_if_enabled/, 'code_sign' )
    end
    contents
}
