# Accelerator

### Statically link CocoaPods frameworks for faster App startup

Xcode Frameworks are a good way to organise code in a large project making it easier
to re-use code with a package manager such as CocoaPods. Unfortunately, from an enginering
point of view breaking the program up into many small parts progressively slows
application launch time as they need to be dynamically loaded one by one.

The solution is to statically link the program as a whole but as
CocoaPods start to be written in Swift this would normally not be an option.

This pod project is a proof of concept that Swift CocoaPods can be
statically linked if you patch a project to perform the following steps:

After pods are built, get the list of their object files using the following command:

```shell
ls -t "$OBJROOT"/Pods.build/$CONFIGURATION$EFFECTIVE_PLATFORM_NAME/*.build/Objects-normal/$CURRENT_ARCH/*.o | egrep -v "$EXCLUDED_OBJECTS_PATTERN" >"$OBJROOT"/Pods.build/$CONFIGURATION$EFFECTIVE_PLATFORM_NAME.objects.filelist
```

Add this as a -filelist of the OTHER_LDFLAGS in the project's Pods.{debug,release}.xcconfig

Substitute empty .framework files into the application package to satisfy the dynamic linker.

Testing has shown that it is possible to shave more than a second off load times
for am average project using ~30 pods using this approach (measured by setting
the DYLD_PRINT_STATISTICS and DYLD_PRINT_APIS environment variables on startup.)

To use, add "pod 'Accelerator'" into your projects Podfile and type "pod update".
Each time you do this, run Pods/Accelerator/patch.rb to patch the project to use
static linkage. You can change the variable EXCLUDED_OBJECTS_PATTERN in the
"Check Pods Manifest.lock" build phase if you encounter any problems with duplicate
symbols on linking. To remove the patch remove the Accelerator" pod and update.

As I say this is a POC though it does work and hopefully if the speed-up is
seen to be real it could be included in the CocoaPods infrastructure itself
which is where it really belongs. If you have any problems or suggestions
please report them using the email address support (at) injectionforxcode.com
or contact me on [@Injection4Xcode](https://twitter.com/#!/@Injection4Xcode).
