# Shopware Cart Service Requirements Specification

## 1. Overview

The Cart Service is the central API in the Shopware core for managing a customer’s shopping cart during a sales‑channel session. Its responsibilities cover the full cart lifecycle from creation through item manipulation, calculation, persistence, and finally conversion into an order.

## 2. Actors & Context

| Actor                   | Description                                                                               |
|-------------------------|-------------------------------------------------------------------------------------------|
| **SalesChannelContext** | Represents the current storefront context (currency, customer, sales channel, permissions, etc.). |
| **CartService**         | Application‑level service that orchestrates cart operations, caching, routing, persisting, and events. |
| **ApiOrderCartService** | API‑specific façade that extends CartService for manual shipping‑cost adjustments and permission management. |

## 3. Functional Requirements

### 3.1 Cart Creation & Retrieval

1. **Create New Cart**
   - **Trigger**: Customer begins a shopping session (or Token is new).
   - **Behavior**: Instantiate a brand‑new `Cart` object associated with the provided token.
   - **API**: `CartService::createNew(string $token): Cart`

2. **Load or Fetch Cached Cart**
   - **Trigger**: Customer revisits storefront or performs additional cart operations.
   - **Behavior**:
     - If a cart for the token is already held in memory and caching is enabled, return it immediately.
     - Otherwise, delegate to the load route to hydrate (from persistence, session, or database) and cache it for subsequent calls.
   - **API**: `CartService::getCart(string $token, SalesChannelContext $context, bool $caching = true, bool $taxed = false): Cart`

### 3.2 Item Manipulation

3. **Add Line Items**
   - **Trigger**: Customer adds one or more products or custom line items.
   - **Behavior**: Route the items to `AbstractCartItemAddRoute`, then return the updated cart.
   - **API**: `CartService::add(Cart $cart, LineItem|LineItem[] $items, SalesChannelContext $context): Cart`

4. **Update Item Quantity**
   - **Trigger**: Customer changes the quantity of a specific line‑item.
   - **Behavior**: Internally maps to the general update route.
   - **API**: `CartService::changeQuantity(Cart $cart, string $identifier, int $quantity, SalesChannelContext $context): Cart`

5. **Batch Update Items**
   - **Trigger**: Bulk changes to multiple items (quantities, custom fields).
   - **Behavior**: Sends an array of item‑update payloads to the update route.
   - **API**: `CartService::update(Cart $cart, array $items, SalesChannelContext $context): Cart`

6. **Remove Single Item**
   - **Trigger**: Customer deletes an item from their cart.
   - **Behavior**: Internally delegates to the multi‑delete route with a single‑element array.
   - **API**: `CartService::remove(Cart $cart, string $identifier, SalesChannelContext $context): Cart`

7. **Remove Multiple Items**
   - **Trigger**: Customer deletes several items at once.
   - **Behavior**: Calls `AbstractCartItemRemoveRoute` with an array of identifiers.
   - **API**: `CartService::removeItems(Cart $cart, array $ids, SalesChannelContext $context): Cart`

### 3.3 Cart Calculation & Persistence

8. **Recalculate Cart**
   - **Trigger**: After item‑ or shipping‑changes, or when explicitly requested.
   - **Behavior**:
     1. Run the `CartCalculator` to compute totals, taxes, discounts, and shipping.
     2. Persist the updated cart state via the configured `AbstractCartPersister`.
   - **API**: `CartService::recalculate(Cart $cart, SalesChannelContext $context): Cart`

### 3.4 Ordering

9. **Place Order from Cart**
   - **Trigger**: Customer completes checkout.
   - **Behavior**:
     1. Invoke the `AbstractCartOrderRoute` to convert the cart into an order record.
     2. Remove the old cart from the in‑memory cache.
     3. Create and dispatch a fresh, empty cart (with the same session token).
     4. Emit a `CartChangedEvent` to notify listeners of the reset.
   - **API**: `CartService::order(Cart $cart, SalesChannelContext $context, RequestDataBag $data): string`
   - **Returns**: The newly created Order’s identifier.

### 3.5 Cart Deletion & Reset

10. **Delete Cart (Session Clear)**
    - **Trigger**: Customer logs out or explicitly clears the cart.
    - **Behavior**: Calls `AbstractCartDeleteRoute` to wipe persisted data for the session.
    - **API**: `CartService::deleteCart(SalesChannelContext $context): void`

11. **Reset Service Cache**
    - **Trigger**: Internal service lifecycle (e.g. kernel reset between requests).
    - **Behavior**: Clears the CartService’s in‑memory cart cache entirely.
    - **API**: `CartService::reset(): void`

## 4. API‑Specific Extensions

In addition to the core CartService, Shopware exposes two small, specialized operations via the `ApiOrderCartService`:

| Operation                         | Description                                                                                                        | API Signature                                                                 |
|-----------------------------------|--------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------|
| **Manual Shipping Cost Override** | Attach a pre‑calculated shipping cost to the cart and trigger recalculation.                                         | `updateShippingCosts(CalculatedPrice $price, SalesChannelContext $context): Cart` |
| **Permission Management**         | Grant or revoke context‑level permissions (e.g. bypass validations) on the sales‑channel context.                  | `addPermission(string $token, string $permission, string $salesChannelId): void`<br>`deletePermission(string $token, string $permission, string $salesChannelId): void` |

## 5. Non‑Functional Requirements

1. **Stateless Service Facade**  
   Although carts are cached in memory per token for request‑scoped performance, the service can be reset without side effects—supporting stateless request handling.

2. **Event‑Driven Notifications**  
   Key state changes (notably after an order) dispatch `CartChangedEvent` so listeners (e.g. storefront, plugins) can react.

3. **Error Handling**  
   All item operations and ordering routes throw domain‑specific exceptions (`CartException`, `InconsistentCriteriaIdsException`) on invalid input or persistence issues.

4. **Extensibility via Routes**  
   Every core action is delegated to an abstract “route” (load, delete, add, update, remove, order) to allow plugins to override behavior.

---

This document captures exactly what the current Shopware Cart Service delivers today—no more, no less.
