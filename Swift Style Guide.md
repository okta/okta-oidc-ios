### Swift code guidelines

- [1. Code formatting](#code-formatting)
- [2. Naming](#naming)
- [3. Coding Style](#coding-style)
- [4. Don'ts](#don'ts)

#### 1. Code Formatting

1.1 Use 4 spaces to indent lines.

1.2. Trim trailing whitespaces (`Xcode` -> `Preferences` -> `Text Editing` -> `Automatically trim trailing whitespace` + `Including whitespace-only lines`).

1.3. No space before colon and one space after it. Exceptions are the ternary operator `? :`, empty dictionary `[:]` and `#selector` syntax `addTarget(_:action:)`.

**Preferred:**
```swift
let fooDictionary: [String: Any]
let testValue: Double
func handle(response: Response)
```
1.4. No semicolons at the end of line.

1.5. Use Xcode indentation (`Command-A`, `Control-I`).

#### 2. Naming

2.1. Use `CamelCase` for types and protocols; `lowerCamelCase` for everything else (function, method, property, constant, variable, argument names, enum case).

2.2. Start factory methods with word `make`.

2.3. Choose clarity over brevity. 

2.4. Name booleans like `isAuthenticated` instead of `authenticated`. 

2.5. Name function parameters where it is appropriate. 

**Preferred:**
```swift
func move(from start: Point, to end: Point)
func makeRequest(withTimeout timeout: TimeInterval, headers: [String: String])
func handleEvents(_ events: [Event])
func compare(_ firstDate: Date, _ secondDate: Date) -> DateResult
```
**Not preferred:**
```swift
func move(_ start: Point, _ end: Point)
func makeRequest(_ timeout: TimeInterval, dict: [String: String])
func handleEvents(events: [Event])
func compare(firstDate: Date, secondDate: Date) -> DateResult
```
2.6. The protocols that describe ***what something is*** should read as nouns (e.g. `Iterator`, `Collection`).

2.7. The protocols that describe ***a capability*** should end in `-able` or `-ible` (e.g. `Comparable`, `Hashable`, `Codable`)

#### 3. Coding style

3.1. Avoid writing `self.` unless it is required by compiler or for readability purposes.

3.2. Use `let` over `var` whenever possible.

3.3. Mark types, functions, properties, constants, variables with `private` where it is applicable. 

3.4. Use `private(set)` for properties to make them readonly (e.g. `IBOutlet`).

3.5. Avoid `internal` access modifier keyword since it is declared by default.

3.6. Use `final` when a class must not (or is not designed to) be inherited (e.g. singleton).

3.7. Omit unnecessary parentheses.

**Preferred:**
```swift
if name == "okta" { ... }
switch tokenType { ... }
let formattedTokens = tokens.map { $0 + "\\" }
tokens.forEach { number in print(number) }
```
**Not preferred:**
```swift
if (name == "okta") { ... }
switch (tokenType) { ... }
let formattedTokens = tokens.map() { $0 + "\\" }
tokens.forEach { (number) in print(number) }
```
3.8. Use compiler inferred context.

**Preferred:**
```swift
view.backgroundColor = .red
let customView = UIView(frame: .zero)
let selector = #selector(viewDidLoad)
let message = "Hello Okta!"
```
**Not preferred:**
```swift
view.backgroundColor = UIColor.red
let customView = UIView(frame: CGRect.zero)
let selector = #selector(MyViewController.viewDidLoad)
let message: String = "Hello Okta!"
```
3.9. Name unused closure parameters as underscores `_`.

3.10. Avoid nested `if/else` statements. Use `Happy Path` rule. 

**Preferred:**
```swift
func message(from response: Response) -> String? {
  guard let context = response.context else {
    return nil
  }

  guard context.isAuthenticated else {
    logOut()
    return nil
  }

  return "User is authenticated"
}

```
**Not preferred:**
```swift
func message(from response: Response) -> String? {
  if let context = response.context {
      if context.isAuthenticated {
        return "User is authenticated" 
      } else {
        logOut()
        return nil 
      }
  } else {
    return nil
  }
}
```

3.11. Use trailing closure syntax when **single** closure parameter.

**Preferred:**
```swift
sendRequest(request) { response, error in
 ...
}
```
**Not Preferred:**
```swift
sendRequest(request, completion: { response, error in
 ...
})
```

3.12. Use multi-line string literal.

**Preferred:**
```swift
let testOktaToken = """
    Lorem Ipsum is simply dummy text of the printing and typesetting industry. \
    Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, \
    when an unknown printer took a galley of type and scrambled it to make \
    a type specimen book.
    """
```

3.13. Use multi-line `guard` statements.

**Preferred:**
```swift
guard let user = response["user"] as? User,
      let username = user.username
else {
    return
}
```
**Not preferred:**
```swift
guard let user = response["user"] as? User, let username = user.username else {
    return
}

guard let user = response["user"] as? User,
      let username = user.username else {
    return
}
```

3.14. Use [XCTUnwrap](https://developer.apple.com/documentation/xctest/3380195-xctunwrap) instead of forced unwrapping in tests.

#### 4. Don'ts

4.1. Don't use `fatalError` or `precondition`. Prefer `assert` if it is recoverable case. If not, handle it in proper way. 

4.2. Avoid implicit unwrapping (`!`), as this will cause a crash if a value is `nil`. Unwrap using `guard let` or `if let` and handle error cases in code as appropriate (e.g. logging, return an error etc.).  

4.3. Don't leave unused or dead code.

4.3. Don't leave commented out code.

4.4. Don't use `DispatchQueue.main.asyncAfter` to fix the issues via delays.

4.5. Don't include your name in source code. Use the common copyright header. 

```swift
/*
 * Copyright (c) 2021-Present, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */
```

### Contribution

The style guide is not set in stone. This document should evolve along with Swift. So feel free to add new items.
