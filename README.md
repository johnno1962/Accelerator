# Accelerator

### Statically link CocoaPods frameworks for faster App startup

Xcode Frameworks are a good way to organise code in a large project making it easier
to re-use code with a package manager such as CocoaPods. Unfortunately, from an enginering
point of view breaking the program up into many small parts progressively slows
application launch time as they need to be dynamically loaded one by one.

The solution is to statically link the program as a whole but as CocoaPods start to be
written in Swift this would normally not be an option. Static linking would would also
offer the possibility of applications using Swift pods to be deployed to iOS 7.

Stop Press:

It seems the benefit of static linking may only be manifest in the debugger
if you [look here](https://github.com/artsy/eidolon/issues/491). Blast.

This pod project is a proof of concept that Swift CocoaPods frameworks can be
statically linked if you patch a project to perform the following steps:

1) After pods are built, get the list of their object files using the following command:

```shell
ls -t "$OBJROOT"/Pods.build/$CONFIGURATION$EFFECTIVE_PLATFORM_NAME/*.build/Objects-normal/$CURRENT_ARCH/*.o | egrep -v "$EXCLUDED_OBJECTS_PATTERN" >"$OBJROOT"/Pods.build/$CONFIGURATION$EFFECTIVE_PLATFORM_NAME.objects.filelist
```

2) Add this as a -filelist of the OTHER_LDFLAGS in the project's Pods.{debug,release}.xcconfig

3) Substitute empty .framework files into the application package to satisfy the dynamic linker
where pods themselves refer to other pods.

Setting DYLD_PRINT_STATISTICS and DYLD_PRINT_APIS on a project using 30
framework pods including swift gives the following times before patching.

```
    total time: 2.8 seconds (100.0%)
    total images loaded:  308 (259 from dyld shared cache)
    total segments mapped: 144, into 3741 pages with 372 pages pre-fetched
    total images loading time: 2.5 seconds (91.4%)
    total dtrace DOF registration time: 0.10 milliseconds (0.0%)
    total rebase fixups:  165,304
    total rebase fixups time: 44.22 milliseconds (1.5%)
    total binding fixups: 321,542
    total binding fixups time: 122.06 milliseconds (4.3%)
    total weak binding fixups time: 0.69 milliseconds (0.0%)
    total bindings lazily fixed up: 0 of 0
    total initializer time: 75.01 milliseconds (2.6%)
```

After patching to statically link the application:

```
    total time: 1.2 seconds (100.0%)
    total images loaded:  276 (259 from dyld shared cache)
    total segments mapped: 48, into 1143 pages with 120 pages pre-fetched
    total images loading time: 1.0 seconds (79.4%)
    total dtrace DOF registration time: 0.08 milliseconds (0.0%)
    total rebase fixups:  145,755
    total rebase fixups time: 54.68 milliseconds (4.2%)
    total binding fixups: 319,488
    total binding fixups time: 140.53 milliseconds (10.9%)
    total weak binding fixups time: 0.39 milliseconds (0.0%)
    total bindings lazily fixed up: 0 of 0
    total initializer time: 68.14 milliseconds (5.3%)
```

While at first glance this should lead to fast app loading time there seem
to be other factors involved and one wonders whether the load times for
30-odd frameworks are going to be significant relative to the nearly
300 Apple frameworks an application links with on startup. Perhaps
the most concrete benefit will be to be able to deploy to iOS7.

To use, add "pod 'Accelerator'" into your projects Podfile and type "pod update".
Each time you do this, run Pods/Accelerator/patch.rb to patch the project to use
static linkage. You can change the variable EXCLUDED_OBJECTS_PATTERN in the
"Check Pods Manifest.lock" build phase if you encounter any problems with duplicate
symbols on linking. To remove the patch remove the Accelerator" pod and update.
The script has been tested with CocoaPods 0.37.2, 0.38.2 and 0.39.0.beta.3

As I say this is a POC though it does work and hopefully if the speed-up is
found to be real it could be included in the CocoaPods infrastructure itself
which is where it really belongs. If you have any problems or suggestions
please report them using the email address support (at) injectionforxcode.com
or contact me on [@Injection4Xcode](https://twitter.com/#!/@Injection4Xcode).
