# Accidental Complexity Guide

A reference for detecting and eliminating accidental complexity in code.

> **Language note:** the principles below are language-agnostic. Code examples are written
> in Python for concreteness; the smell, the reasoning, and the refactoring apply equally
> to Java, C#, TypeScript, Go, Kotlin, Ruby, etc. Where a detection pattern is shown as a
> regex, treat it as "search your codebase for the equivalent construct."

## What Is Accidental Complexity?

Fred Brooks distinguished between **essential complexity** (inherent to the problem
domain) and **accidental complexity** (introduced by our solution). Accidental complexity
is code that doesn't serve the business problem — it exists only because of implementation
choices, defensive habits, or premature abstraction.

**Why it matters:**
- Increases cognitive load for readers
- Makes code harder to change safely
- Hides the essential logic under ceremony
- Compounds over time ("complexity attracts complexity")

## Priority Smells

### 1. Null/Optional Complexity (Critical Priority)

The most important smell to eliminate. Every null/`None`/`Optional` check is a design
decision that should be challenged. (`None` in Python, `null` in Java/C#/JS, `nil` in
Go/Ruby, `Option`/`Optional` wrappers — same idea.)

#### 1.1 Null Checks in Domain Logic

**Smell:** `if x is not None:` / `if (x != null)` / `if x:` guards inside domain/service code.

**Why it's bad:** Null checks are defensive programming. In domain logic, they signal that
the contract is unclear — who is responsible for ensuring the value exists?

**Detection:**
- Search for null/None guards at the start of methods, and nested null checks.

**Bad:**
```python
class PriceCalculator:
    def calculate(self, product: Product, discount: Discount | None = None) -> Money:
        base = product.base_price
        if discount is not None:
            if discount.is_valid():
                base = base - discount.amount
        return base
```

**Good — push the decision up:**
```python
class PriceCalculator:
    def calculate(self, product: Product) -> Money:
        return product.base_price

    def calculate_with_discount(self, product: Product, discount: Discount) -> Money:
        if not discount.is_valid():
            raise InvalidDiscountError(discount)
        return product.base_price - discount.amount
```

**When it's OK:**
- Adapter code translating external data (null is the reality of the external world)
- Repository code handling "not found" cases
- Never in domain/service logic

#### 1.2 Optional Arguments Never Used as Null

**Smell:** an optional/nullable parameter that no caller ever passes as null.

**Why it's bad:** The optionality is a lie. It adds complexity (null checks) for a case
that never happens. Often a leftover from "maybe we'll need this" thinking.

**Detection:**
- Find optional/nullable parameters, then search all callers — does anyone pass null or
  omit the argument?

**Bad:**
```python
def send_notification(user: User, channel: Channel | None = None) -> None:
    if channel is None:
        channel = Channel.EMAIL
    # ... rest of logic
```

If every caller passes a channel, remove the optionality:

**Good:**
```python
def send_notification(user: User, channel: Channel) -> None:
    # ... logic without null check
```

**When it's OK:**
- Genuinely optional configuration with sensible defaults
- Builder pattern where partial construction is intentional

#### 1.3 Defensive Null Returns

**Smell:** Methods that return a nullable/`Optional` when null means "something went wrong."

**Why it's bad:** Pushes error handling to every caller. The caller now needs a null
check, spreading complexity.

**Bad:**
```python
def find_user(user_id: UserId) -> User | None:
    # Returns None if not found, None if invalid ID, None if DB error...
    ...
```

**Good — be explicit about failure modes:**
```python
def get_user(user_id: UserId) -> User:
    """Raises UserNotFoundError if user doesn't exist."""
    ...

def find_user(user_id: UserId) -> User | None:
    """Returns None only for 'not found'. Raises on other errors."""
    ...
```

---

### 2. Exception Handling Complexity (Critical Priority)

#### 2.1 Multi-Layer Exception Handling

**Smell:** The same exception is caught at multiple layers (adapter → service → controller).

**Why it's bad:** Each layer adds try/except ceremony. Often the middle layers just
re-raise or wrap without adding value.

**Detection:**
- Multiple try/catch blocks in a call chain.
- `except SomeError: raise` or catch-and-rewrap patterns; count catches per file/module.

**Bad:**
```python
# adapter.py
def fetch_data():
    try:
        return client.get()
    except ClientError as e:
        raise DataFetchError(e)

# service.py
def process():
    try:
        data = fetch_data()
    except DataFetchError:
        raise ProcessingError("Failed to fetch")

# controller.py
def handle():
    try:
        process()
    except ProcessingError as e:
        return error_response(e)
```

**Good — handle at boundaries only:**
```python
# adapter.py — translate external errors to domain errors
def fetch_data():
    try:
        return client.get()
    except ClientError as e:
        raise DataFetchError(e)

# service.py — let errors propagate
def process():
    data = fetch_data()
    return transform(data)

# controller.py — use the framework's error handler
@app.exception_handler(DomainError)
def handle_domain_error(e: DomainError):
    return error_response(e)
```

**When it's OK:**
- Adapter boundaries (translating library errors to domain errors)
- Framework-level error handlers
- Cleanup/resource management (but prefer context managers / try-with-resources / `defer`)

#### 2.2 Catching Broad Exceptions

**Smell:** `except Exception:` / `catch (Exception)` / bare `except:`.

**Why it's bad:** Catches everything, including programming errors. Hides bugs.

**Bad:**
```python
try:
    result = complex_operation()
except Exception:
    logger.error("Something went wrong")
    return None
```

**Good:**
```python
try:
    result = complex_operation()
except SpecificNetworkError as e:
    logger.error("Network failed", exc_info=e)
    raise ServiceUnavailableError() from e
```

#### 2.3 Re-Raising the Same Exception Type

**Smell:** catch `FooError` only to throw a new `FooError`.

**Why it's bad:** Adds a try/catch block that does nothing useful. If you're not
translating or enriching, don't catch.

---

## General Code Smells

### 3. Boolean Flag Parameters

**Smell:** a boolean parameter that significantly changes behaviour
(`get_users(include_deleted=False)`).

**Why it's bad:** The function does two different things. Callers must understand the flag.
Often leads to internal `if flag:` branches.

**Detection:** parameters named `include_*`, `with_*`, `is_*`, `should_*`, `enable_*`;
boolean parameters generally.

**Bad:**
```python
def get_users(include_inactive: bool = False) -> list[User]:
    query = select(User)
    if not include_inactive:
        query = query.where(User.active == True)
    return session.execute(query).all()
```

**Good — two methods with clear intent:**
```python
def get_active_users() -> list[User]:
    return session.execute(select(User).where(User.active == True)).all()

def get_all_users() -> list[User]:
    return session.execute(select(User)).all()
```

**When it's OK:** configuration flags that don't change core behaviour; feature flags at
system boundaries.

### 4. Long Parameter Lists

**Smell:** functions with more than ~4 parameters.

**Why it's bad:** Hard to remember order, easy to swap arguments, signals the function
does too much.

**Bad:**
```python
def create_order(
    customer_id, product_id, quantity, shipping_address,
    billing_address, discount_code, gift_wrap, delivery_date,
) -> Order:
    ...
```

**Good — introduce a parameter object:**
```python
@dataclass
class OrderRequest:
    customer_id: int
    product_id: int
    quantity: int
    shipping: Address
    billing: Address
    options: OrderOptions

def create_order(request: OrderRequest) -> Order:
    ...
```

### 5. Primitive Obsession

**Smell:** Using primitive types (str, int) for domain concepts.

**Why it's bad:** No type safety, no place for behaviour, easy to mix up parameters of the
same type.

**Bad:**
```python
def transfer(from_account: str, to_account: str, amount: int) -> None:
    ...  # Easy to swap from/to; amount could be negative
```

**Good:**
```python
@dataclass(frozen=True)
class AccountId:
    value: str

@dataclass(frozen=True)
class Money:
    cents: int
    def __post_init__(self):
        if self.cents < 0:
            raise ValueError("Money cannot be negative")

def transfer(source: AccountId, destination: AccountId, amount: Money) -> None:
    ...
```

### 6. Data Clumps

**Smell:** The same group of parameters/fields appears together in multiple places.

**Why it's bad:** Signals a missing abstraction. Changes require updating multiple places.

**Bad:**
```python
def format_address(street, city, postal_code) -> str: ...
def validate_address(street, city, postal_code) -> bool: ...
def ship_to(street, city, postal_code) -> None: ...
```

**Good:** introduce an `Address` value object and pass it around.

### 7. Middle Man / Unnecessary Delegation

**Smell:** A class that only delegates to another class without adding value.

**Why it's bad:** Extra indirection with no benefit. Caller could use the delegate directly.

**Bad:**
```python
class UserService:
    def __init__(self, repo: UserRepository):
        self.repo = repo
    def get(self, id): return self.repo.get(id)
    def save(self, user): self.repo.save(user)
    def delete(self, id): self.repo.delete(id)
```

**Good:** remove the middle man and let callers use the repository directly, or add actual
business logic to justify the service layer.

### 8. Feature Envy

**Smell:** A method that uses more features of another class than its own.

**Why it's bad:** Logic is in the wrong place. The method should probably live on the
other class.

**Detection:** methods with many `other_object.field` accesses; chained access like
`self.order.customer.address.city`.

**Good:** move the behaviour onto the class that owns the data
(`order.customer.format_shipping_label()`).

### 9. Speculative Generality (YAGNI)

**Smell:** Abstractions, parameters, or code paths that aren't used yet.

**Why it's bad:** Complexity for imagined future needs. The future rarely matches predictions.

**Detection:** abstract base classes / interfaces with one implementation; parameters
always passed the same value; code paths never executed.

**Good:** remove the abstraction until you have a second real use case.

### 10. God Objects / Large Classes

**Smell:** Classes with many responsibilities, methods, and fields.

**Detection:** >10 public methods, >5 dependencies, file size >300 lines.

**Refactoring:** extract cohesive groups of methods into separate classes.

### 11. Unnecessary State

**Smell:** Instance attributes that could be local variables or parameters.

**Why it's bad:** State makes reasoning harder. Stateless functions are easier to test and
compose.

**Bad:**
```python
class Calculator:
    def __init__(self): self.current_value = 0
    def add(self, x): self.current_value += x
    def get_result(self): return self.current_value
```

**Good:**
```python
def add(a: int, b: int) -> int:
    return a + b
```

### 12. Nested Conditionals (Arrow Anti-Pattern)

**Smell:** Deeply nested if/else blocks forming an "arrow" shape.

**Detection:** indentation depth >3 levels; multiple nested `if` statements.

**Bad:**
```python
def process(order):
    if order is not None:
        if order.is_valid():
            if order.customer.is_active():
                if order.has_stock():
                    return fulfill(order)
                else:
                    return out_of_stock()
            else:
                return inactive_customer()
        else:
            return invalid_order()
    else:
        return no_order()
```

**Good — use early returns (guard clauses):**
```python
def process(order):
    if order is None:
        return no_order()
    if not order.is_valid():
        return invalid_order()
    if not order.customer.is_active():
        return inactive_customer()
    if not order.has_stock():
        return out_of_stock()
    return fulfill(order)
```

### 13. Temporary Fields

**Smell:** Instance attributes that are only set in some code paths.

**Why it's bad:** The object's state is unpredictable. Callers don't know which fields are valid.

**Good — return a result object instead of mutating self:**
```python
@dataclass
class ReportResult:
    summary: Summary
    details: Details

class ReportGenerator:
    def generate(self, data: Data) -> ReportResult:
        return ReportResult(summary=summarize(data), details=extract_details(data))
```

### 14. Mutable Default Arguments

**Smell:** a mutable value used as a default argument (Python: `def foo(items=[])`).

**Why it's bad:** the default is shared across calls — a classic Python gotcha; analogous
shared-mutable-default bugs exist in other languages.

**Bad:**
```python
def append_to(item: str, target: list[str] = []) -> list[str]:
    target.append(item)
    return target
```

**Good:**
```python
def append_to(item: str, target: list[str] | None = None) -> list[str]:
    if target is None:
        target = []
    target.append(item)
    return target
```

Or better — avoid the mutation entirely.

### 15. Inappropriate Intimacy

**Smell:** Classes that know too much about each other's internals.

**Detection:** accessing private attributes; long chains of attribute access.

**Refactoring:** add methods to expose needed behaviour without exposing internals.

### 16. Inconsistent Abstraction Levels

**Smell:** A function that mixes high-level operations with low-level details.

**Bad:**
```python
def create_user(name: str, email: str) -> User:
    if not re.match(r'^[\w\.-]+@[\w\.-]+\.\w+$', email):
        raise InvalidEmailError(email)
    user = User(name=name, email=email)
    connection = psycopg2.connect(DATABASE_URL)
    cursor = connection.cursor()
    cursor.execute("INSERT INTO users ...")
    connection.commit()
    return user
```

**Good:**
```python
def create_user(name: str, email: Email) -> User:
    user = User(name=name, email=email)
    user_repository.save(user)
    return user
```

### 17. Dead Code / Unreachable Branches

**Smell:** Code that can never execute (`if False:`, conditions always true/false,
uncalled methods).

**Action:** delete it.

### 18. Anemic Domain Model

**Smell:** Domain objects that are just data containers with no behaviour.

**Why it's bad:** Business logic ends up in services, scattered across the codebase.

**Good — put behaviour on the model:**
```python
@dataclass
class Order:
    items: list[Item]
    status: OrderStatus

    def total(self) -> Money:
        return sum((item.price for item in self.items), Money.zero())

    def can_cancel(self) -> bool:
        return self.status == OrderStatus.PENDING

    def cancel(self) -> None:
        if not self.can_cancel():
            raise CannotCancelError(self)
        self.status = OrderStatus.CANCELLED
```

---

## Severity Model

| Severity | Indicators |
|----------|------------|
| Critical | Null checks in domain logic, optional params never used as null, exception handling masking design flaws |
| Major | Multi-layer try/catch, boolean flags splitting behaviour, unnecessary delegation, feature envy, god objects |
| Minor | Long param lists, speculative generality, unnecessary state, primitive obsession, nested conditionals |

## Detection Cheat Sheet

| Smell | What to search for |
|-------|--------------------|
| Null checks | `is None` / `is not None` / `!= null` / `== null` guards |
| Optional params | nullable params defaulting to null |
| Broad catch | `except Exception` / `catch (Exception)` / bare catch |
| Boolean flags | boolean parameters with defaults |
| Mutable defaults | mutable literals as default arguments |
| Long functions | distance between one function definition and the next |
| Private access | `._field` / `.__field` cross-object access |

## References

- **Refactoring** (Martin Fowler) — the canonical catalogue of code smells and refactorings
- **Clean Code** (Robert C. Martin) — functions, naming, error handling
- **Growing Object-Oriented Software, Guided by Tests** (Freeman & Pryce) — ports and adapters, test design
- **Domain-Driven Design** (Eric Evans) — rich domain models vs anemic models
- **A Philosophy of Software Design** (John Ousterhout) — complexity management, deep vs shallow modules
