# UI Browser 4

As bart of the [handover by Bill Cheeseman of his UI Browser application to Late Night Software](https://latenightsw.com/freeware/ui-browser/), we received the source code to an unfinished UI Browser 4.  UI Browser 4 is a rewrite of UI Browser in Swift.

In accordance with Bill's wishes, the UI Browser 4 source code is available to the public as open source project in this repository.

## Status

The project builds and runs with Apple's Xcode 14.

UI Browser 4 is an **UNFINISHED WORK** and is not fully usable in its current form.

The source code mentions UI Browser 3 in a number of places.  Despite these references, this is not the UI Browser 3 source code and cannot be altered to produce the existing UI Browser 3 application.

## Requirements

- macOS Monterey or later
- Xcode 14 or later

## Support/Discussion

Late Night Software maintains a section on its on-line forum for [UI Browser user discussions](https://forum.latenightsw.com/c/uibrowser/17).

## Building

- clone this repository
- open the `UI Browser.xcworkspace` project using Xcode 14
- issue the Build > Run menu command run the application

## Contact

[Mark Alldritt](mailto:alldritt@latenightsw.com) - Late Night Software Ltd.

# Contributing

The UI Browser project is released under the MIT license. Any contributions to this repository are understood to fall under the same license.

- Bug fixes and typo corrections are always welcome.
- Bug reports must include simple steps for reproduction and clearly indicate the OS version where the bug arises.
- PRs should match the style of existing code.
- PRs should be as small as possible, and must not contain bundled unrelated changes.
- PRs must include updates for documentation (see: the `UIBrwoser4/docs` directory) wherever relevant.
- PRs must pass the entire test suite.
- When modifying UI Browser, avoid generating warnings.

Please refrain from submitting PRs to this repository containing new features without first discussing their inclusion in an Issue. There are an infinite number of features that could potentially be added, but creative constraints are also valuable. If you have a differing vision, feel empowered to explore it in your own fork of the project- that's what permissive licenses are for.

Late Night Software will produce and host UI Browser 4 builds as new versions are developed.

# LICENSE

Copyright (c) 2022 Bill Cheeseman and PFiddlesoft

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
