# Project Context
Critical project context lives in `PROJECT.md`. It describes all aspects of the FireSight project.

# Information Accuracy
- When debugging a problem, make decisions based on evidence, not guesswork.
- The current year is 2026. Assume your knowledge of LLM/AI capabilities and models is outdated unless you refer to documentation or online resources.
- Similarly, don't assume you know current details about any dependency (e.g. versions, capabilities) without referring to documentation.
  - You should always identify the latest stable version before adding a dependency.
  - You should research to *discover* suitable dependencies as well.
- Strongly prefer popular, well-maintained projects as dependencies instead of random packages or repos that you come across - do the extra research to ensure they fit within that category.
- If helping the developer install a dependency, refer to its actual setup tutorial or quickstart guide.

# Development Practices
- Enforce type safety where possible.
- Big features belong on new branches, not `main`.
  - If the developer asks you to start work on a new feature but they aren't on a relevant branch, suggest switching to or creating one.
- Don't push to remote or open PRs without asking the user. Commiting locally to the branch at your discretion is acceptable.
- Consult the user before adding new dependencies to solve a problem.
- Big problems should be broken down into smaller ones - in other words, if a function or type is achieving too many things at once, it should be broken up into helpers.
- Every function and type should have a concise but clear purpose statement.
- Write tests (and any necessary mock data) for every function, including helpers, to cover happy paths, edge cases, and regressions.
  - Subagents can be used for this in order to preserve context.
- Always attempt to verify the success of your work in some form as opposed to assuming it is correct.
  - This could include taking screenshots of the app or actually simulating a user flow.
- Ensure the project compiles before finalizing your work.
- Encourage the developer to use your Plan Mode (or equivalent) for large features.
- If preferred tooling is not present on the developer's device, guide them through the installation rather than working without the optimal tools unless they cannot be installed.
- When you implement or make changes to a feature, update related documentation and/or comments once finished.
  - When adding new major dependencies, add the corresponding docs to the External Docs section in `PROJECT.md`.
  - Update the agent skills in `.agents/skills/*` as well if needed.

# Technical Details
For full details, see `PROJECT.md`.
- Use `adb` to debug the app on connected Android devices or emulators.
  - You can also use `adb` to simulate user actions and verify success.
- Use the corresponding tools for iOS to debug the app on that platform.
  - Use `xcrun simctl list devices available` to find simulators.
  - Use `xcrun simctl boot <simulator-udid>` and `open -a Simulator` to start one.
  - Use `flutter run -d <simulator-udid>` to run the app on iOS Simulator.
  - Use `flutter build ios --no-codesign` for a compile-only iOS verification.
  - iOS currently requires CocoaPods and deployment target 16.0 because the Cactus framework (v1.3.0+) and FlutterFire pods require iOS 16+.
  - **Debugging:** If the app stops at `NOTIFY_DEBUGGER_ABOUT_RX_PAGES` in LLDB, this is a normal Flutter/Dart VM behavior. Use the provided `.lldbinit` to automatically continue past these breakpoints.
  - Always implement features with cross-platform compatibility in mind.  - Much of the architecture is cross-platform out of the box (e.g. Flutter, Cactus Flutter SDK).
  - Some dependencies have both iOS and Android versions available (e.g. Meta Glasses SDK).
  - Without devices/emulators from both platforms available, it may be challenging to implement features for both platforms. You should design abstractions to cleanly handle both cases, and leave stubs for components which cannot be verifiably implemented due to platform limitations. This should be communicated clearly to the developer and included in PR descriptions.
- Use the GitHub CLI (`gh`) to interact with GitHub-specific features outside of `git`'s scope (like PRs). 
- Local LLM inference capability via Cactus is a requirement - do not toss it out merely due to it being challenging.
- When designing agentic systems, use structured output APIs and tool calls as opposed to relying on prompting where possible.
- Even when Powershell is available, prefer Bash unless there is a specific reason to use Powershell.
- If the Flutter/Dart MCP tool is not available to you, and you are performing relevant work, ask the user to install it as it will help you debug issues with your code. 
  - Docs: https://docs.flutter.dev/ai/mcp-server
