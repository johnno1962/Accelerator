#!/usr/bin/env ruby

#  Accelerator.rb
#  Accelerator
#
#  Created by John Holdsworth on 30/08/2015.
#  Copyright (c) 2015 John Holdsworth. All rights reserved.

Dir.chdir( File.dirname(__FILE__) )

def patch( path, &patcher )
    contents = File.open( path, "r" ).read()
    patched = patcher.call( contents )
    if patched != contents
        print( "Patching #{path}\n" )
        File.open( path, "w" ).write( patched )
    end
end

# With static linking can deploy to iOS 7

patch( "../Pods.xcodeproj/project.pbxproj" ) { |contents|
    contents.gsub( /(IPHONEOS_DEPLOYMENT_TARGET =) 8.0/, '\1 7.0' )
}

# add object file list to OTHER_LDFLAGS and remove pod franmeworks

podproj = File.open( "../Pods.xcodeproj/project.pbxproj", "r" ).read()

pods = podproj.scan( /productReference = \w+ \/\* (\w+).framework \*\// ).map { |capture| capture[0] }

pods = (pods + Dir.glob( "../*" ).map { |dir| dir.sub( /..\//, '' ) }).uniq

['debug', 'release'].each { |config|
    patch( "../Target Support Files/Pods/Pods.#{config}.xcconfig" ) { |contents|
        ldflags = contents.match( /OTHER_LDFLAGS = (?:-filelist \S+ )?(.*)/ ).captures[0]
        pods.each { |pod| ldflags.gsub!( / -framework "#{pod}"/, '' ) }
        contents.sub( /(OTHER_LDFLAGS = ).*/,
                     '\1-filelist "$(OBJROOT)/Pods.build/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME).objects.filelist" '+ldflags )
    }
}

# patch pod framework installer to  do nothing but remove embedded frameworks

patch( "../Target Support Files/Pods/Pods-frameworks.sh" ) { |contents|
    contents = contents.sub( /install_framework\(\)\n/, <<BASH )
install_framework()
{
    local framework=$(basename "$1")
    local podname=${framework%.*}

    local source="${BUILT_PRODUCTS_DIR}/Accelerator.framework"
    local destination="${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/${framework}"
    local plist="${destination}/Info.plist"

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

        if [ "${podname}" != "Accelerator" ]; then
            plutil -convert xml1 "${plist}"
            /usr/libexec/PlistBuddy -c "set CFBundleIdentifier org.cocoapods.$podname" "${plist}"
            /usr/libexec/PlistBuddy -c "set CFBundleExecutable $podname" "${plist}"
            plutil -convert binary1 "${plist}"

            mv "${destination}/Accelerator" "${destination}/${podname}"
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

# patch original project to place list of framework objects into a file for linking

Dir.glob("../../*.xcodeproj/project.pbxproj").each { |project|
    patch( project ) { |contents|
        contents.sub( /(shellScript = ")(diff \\\"\$\{PODS_ROOT\}\/..\/Podfile.lock\\\")/, '\1# Accelerator patch here...\\nexport EXCLUDED_OBJECTS_PATTERN=\\\"/BIT\\\"\\nls -t \\\"$OBJROOT\\\"/Pods.build/$CONFIGURATION$EFFECTIVE_PLATFORM_NAME/*.build/Objects-normal/$CURRENT_ARCH/*.o | egrep -v \\\"$EXCLUDED_OBJECTS_PATTERN\\\" >\\\"$OBJROOT\\\"/Pods.build/$CONFIGURATION\$EFFECTIVE_PLATFORM_NAME.objects.filelist\\n\2' )
    }
}
