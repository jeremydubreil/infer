(*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open! IStd
open OUnit2

let path_tests _ =
  let yes p = assert_bool p (SwiftObjCNullabilityIssue.is_system_framework_path p) in
  let no p = assert_bool p (not (SwiftObjCNullabilityIssue.is_system_framework_path p)) in
  yes
    "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS17.4.sdk/System/Library/Frameworks/UIKit.framework/Headers/UIView.h" ;
  yes
    "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX14.4.sdk/System/Library/Frameworks/Foundation.framework/Headers/NSString.h" ;
  yes "/some/buck-out/cache/MacOSX14.sdk/usr/include/sys/types.h" ;
  yes "/opt/vendor/Prebuilt.framework/Headers/Prebuilt.h" ;
  no "/home/user/proj/fbobjc/CK/CKBloksRenderComponent.h" ;
  no "/home/user/proj/fbobjc/Util/CTAudioProcessor.h" ;
  no "/home/user/proj/MyApp/Sources/UIDFBRichTextViewDescriptor.h"


let tests = "swift_objc_nullability_issue_test_suite" >::: ["path_tests" >:: path_tests]
