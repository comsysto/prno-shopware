# Shopware Cart Service - Detailed Technical Specification for External Implementation

## Document Purpose

This specification provides complete technical requirements for reimplementing Shopware's Cart Service. All specifications are based on the current Shopware implementation and contain no additional functionality. External development teams can use this document to create a functionally equivalent cart system.

## 1. Domain Model Specification

### 1.1 Cart Entity Specification

**Primary Entity: Cart**
```php
class Cart extends Struct {
    protected string $token;                          // UUID v4 format, unique identifier
    protected LineItemCollection $lineItems;         // Collection of line items
    protected ErrorCollection $errors;               // Validation errors
    protected DeliveryCollection $deliveries;        // Shipping deliveries
    protected TransactionCollection $transactions;   // Payment transactions
    protected CartPrice $price;                      // Calculated cart totals
    protected bool $modified = false;                // Change tracking flag
    protected ?string $customerComment = null;       // Customer comment (max 2000 chars)
    protected ?string $affiliateCode = null;         // Affiliate tracking code
    protected ?string $campaignCode = null;          // Campaign tracking code
    protected ?string $source = null;                // Cart source identifier
    protected ?CartDataCollection $data = null;      // Transient calculation data
    protected array $ruleIds = [];                   // Applied rule IDs
    protected ?CartBehavior $behavior = null;        // Processing behavior configuration
}
```

**Business Rules for Cart:**
- Token must be UUID v4 format
- Cart cannot be modified if marked as unmodified
- Empty carts (no line items) cannot proceed to checkout
- Customer comment limited to 2000 characters
- Affiliate and campaign codes must be alphanumeric strings

### 1.2 LineItem Entity Specification

**Core Entity: LineItem**
```php
class LineItem extends Struct {
    protected string $id;                             // Max 100 chars, pattern: [a-zA-Z0-9-_.]
    protected string $type;                           // LINE_ITEM_TYPE constants
    protected ?string $referencedId = null;          // Referenced entity ID
    protected int $quantity = 1;                     // Minimum 1, positive integer
    protected ?string $label = null;                 // Display label
    protected ?string $description = null;           // Item description
    protected array $payload = [];                   // Flexible data storage
    protected ?PriceDefinitionInterface $priceDefinition = null; // Price calculation definition
    protected ?CalculatedPrice $price = null;        // Calculated price result
    protected bool $good = true;                      // Item type flag (good vs service)
    protected ?MediaEntity $cover = null;            // Display media
    protected ?DeliveryInformation $deliveryInformation = null; // Shipping info
    protected LineItemCollection $children;          // Nested line items
    protected ?Rule $requirement = null;             // Eligibility rule
    protected bool $removable = true;                // Can be removed from cart
    protected bool $stackable = true;                // Can have quantity > 1
    protected ?QuantityInformation $quantityInformation = null; // Quantity constraints
    protected bool $modified = false;                // Change tracking
    protected bool $shippingCostAware = true;        // Contributes to shipping costs
    protected ?\DateTimeInterface $dataTimestamp = null; // Data freshness
    protected ?string $dataContextHash = null;       // Context validation hash
    protected array $states = [];                    // State flags
    protected bool $modifiedByApp = false;           // Modified by app extension
}
```

**LineItem Type Constants:**
```php
const PRODUCT_LINE_ITEM_TYPE = 'product';        // Physical/digital products
const CUSTOM_LINE_ITEM_TYPE = 'custom';          // Custom items
const CREDIT_LINE_ITEM_TYPE = 'credit';          // Credits/refunds
const PROMOTION_LINE_ITEM_TYPE = 'promotion';    // Promotional items
const DISCOUNT_LINE_ITEM = 'discount';           // Discount applications
const CONTAINER_LINE_ITEM = 'container';         // Grouped items container
```

**LineItem Validation Rules:**
```php
// ID Validation
- Maximum length: 100 characters
- Allowed pattern: /^[a-zA-Z0-9-_.]+$/
- Must be unique within cart scope

// Quantity Validation  
- Minimum value: 1
- Must be positive integer
- Stackable items: can modify quantity
- Non-stackable items: fixed at quantity 1
- Child items: quantity must be multiple of parent quantity

// Payload Validation
- Only scalar values (string, int, float, bool) and arrays allowed
- Nested arrays permitted
- Objects not allowed (except specific whitelisted types)
- Protected keys excluded from serialization
```

### 1.3 Price and Tax Value Objects

**CalculatedPrice Value Object:**
```php
class CalculatedPrice extends Struct {
    protected float $unitPrice;                       // Price per unit
    protected int $quantity;                          // Quantity
    protected float $totalPrice;                      // Total price (unitPrice * quantity)
    protected CalculatedTaxCollection $calculatedTaxes; // Applied taxes
    protected TaxRuleCollection $taxRules;           // Tax calculation rules
    protected ?array $listPrice = null;              // Original list price
    protected ?array $regulationPrice = null;        // Regulation price info
    protected ?ReferencePrice $referencePrice = null; // Unit reference price
}
```

**CartPrice Value Object:**
```php
class CartPrice extends Struct {
    protected float $netPrice;                        // Net total
    protected float $totalPrice;                      // Gross total
    protected float $positionPrice;                   // Sum of line item prices
    protected float $rawTotal;                        // Pre-discount total
    protected CalculatedTaxCollection $calculatedTaxes; // Tax breakdown
    protected TaxRuleCollection $taxRules;           // Applied tax rules
    protected string $taxStatus;                      // gross|net|tax-free
}
```

**Tax Calculation Objects:**
```php
class CalculatedTax extends Struct {
    protected float $tax;                             // Tax amount
    protected float $taxRate;                         // Tax percentage
    protected float $price;                           // Price basis for tax
}

class TaxRule extends Struct {
    protected float $taxRate;                         // Tax percentage (0-100)
    protected float $percentage;                      // Distribution percentage (0-100)
}
```

### 1.4 Collection Classes Specification

**LineItemCollection:**
```php
class LineItemCollection extends EntityCollection {
    // Core Methods (must implement)
    public function add(Entity $entity): void;              // Add line item
    public function remove(string $key): void;              // Remove by ID
    public function has(string $key): bool;                 // Check existence
    public function get(string $key): ?LineItem;            // Get by ID
    public function clear(): void;                          // Remove all items
    
    // Cart-Specific Methods (required implementations)
    public function filterType(string $type): self;         // Filter by type
    public function filterGoods(): self;                    // Filter goods only
    public function filterGoodsFlat(): self;               // Flat goods filter
    public function getFlat(): self;                        // Flatten hierarchy
    public function getPrices(): PriceCollection;          // Extract prices
    public function hasLineItemWithState(string $state): bool; // Check states
    public function getLineItemWithState(string $state): ?LineItem; // Get by state
    public function removeElement(LineItem $lineItem): bool; // Remove instance
    
    // Business Logic Methods
    public function exists(LineItem $toCheck): bool;        // Check if item exists
    public function sortByPriority(): void;                // Sort by priority
    public function getElements(): array;                   // Get all as array
    protected function getExpectedClass(): string;         // Return LineItem::class
}
```

## 2. Business Logic Specification

### 2.1 Cart Lifecycle Operations

**Cart Creation Workflow:**
```php
// CartFactory::createNew() Implementation Requirements
1. Generate UUID v4 token using Uuid::randomHex()
2. Initialize empty LineItemCollection
3. Initialize empty ErrorCollection  
4. Initialize empty DeliveryCollection
5. Initialize empty TransactionCollection
6. Set CartPrice with zero values
7. Set modified = false
8. Dispatch CartCreatedEvent with cart and context
9. Return new Cart instance
```

**Cart Loading Workflow:**
```php
// CartService::getCart() Implementation Requirements  
1. Check in-memory cache by token first
2. If not cached, load from persister (database/redis)
3. If cart exists:
   a. Deserialize cart data
   b. Validate cart integrity
   c. Check rule hash for recalculation need
   d. Recalculate if rules changed
   e. Cache in memory
   f. Dispatch CartLoadedEvent
4. If cart doesn't exist, create new cart
5. Return cart instance
```

**Cart Calculation Workflow:**
```php
// CartCalculator::calculate() Implementation Requirements
1. Load applicable rules via CartRuleLoader
2. Create calculation context with rules
3. Execute Processor.process() with context
4. Generate cart hash using CartContextHasher
5. Mark cart as unmodified
6. Set rule IDs on cart
7. Return calculated cart
```

### 2.2 Line Item Management Operations

**Add Line Item Workflow:**
```php
// Detailed implementation for LineItem addition
1. Validate line item ID format and uniqueness
2. Check rate limiting for IP address
3. Validate line item data structure
4. Check if stackable item already exists
5. If exists and stackable:
   a. Merge quantities
   b. Update existing item payload if needed
   c. Dispatch BeforeLineItemQuantityChangedEvent
   d. Dispatch AfterLineItemQuantityChangedEvent
6. If new item:
   a. Dispatch BeforeLineItemAddedEvent  
   b. Add to line items collection
   c. Mark cart as modified
   d. Dispatch AfterLineItemAddedEvent
7. Trigger cart recalculation
8. Return updated cart
```

**Remove Line Item Workflow:**
```php
// LineItem removal implementation
1. Validate line item exists in cart
2. Check if item is removable (removable = true)
3. If item has children, remove all children recursively
4. Dispatch BeforeLineItemRemovedEvent
5. Remove item from line items collection
6. Remove any associated deliveries/transactions
7. Mark cart as modified
8. Dispatch AfterLineItemRemovedEvent  
9. Trigger cart recalculation
10. Return updated cart
```

**Update Line Item Workflow:**
```php
// LineItem quantity/payload update implementation
1. Validate line item exists
2. For quantity changes:
   a. Validate new quantity > 0
   b. Check if item is stackable
   c. Validate child item quantity multiples
   d. Dispatch BeforeLineItemQuantityChangedEvent
   e. Update quantity
   f. Dispatch AfterLineItemQuantityChangedEvent
3. For payload changes:
   a. Validate payload data types
   b. Check protected key restrictions
   c. Merge with existing payload
4. Mark line item as modified
5. Mark cart as modified
6. Trigger cart recalculation
7. Return updated cart
```

### 2.3 Price Calculation Algorithms

**Tax Calculation Algorithm:**
```php
// AmountCalculator implementation requirements
1. Process each line item price:
   a. Get price definition
   b. Calculate base price
   c. Apply quantity multiplication
   d. Calculate tax based on tax state (gross/net/free)
   e. Round according to currency rules
2. Aggregate all line item prices
3. Calculate cart-level discounts/surcharges
4. Apply delivery costs
5. Calculate final tax amounts
6. Round final totals
7. Create CartPrice with all calculations
```

**Tax State Handling:**
```php
// Tax calculation based on context tax state
switch ($taxState) {
    case SalesChannelContext::TAX_STATE_GROSS:
        // Prices include tax - calculate net from gross
        $netPrice = $grossPrice / (1 + $taxRate);
        $tax = $grossPrice - $netPrice;
        break;
        
    case SalesChannelContext::TAX_STATE_NET:  
        // Prices exclude tax - calculate gross from net
        $tax = $netPrice * $taxRate;
        $grossPrice = $netPrice + $tax;
        break;
        
    case SalesChannelContext::TAX_STATE_FREE:
        // Tax-free calculation
        $netPrice = $grossPrice = $inputPrice;
        $tax = 0.0;
        break;
}
```

**Rounding Algorithm:**
```php
// CashRounding implementation for currency-specific rounding
class CashRounding {
    protected float $interval;    // Rounding interval (0.01, 0.05, etc.)
    protected int $decimals;     // Decimal places
    protected bool $roundForNet; // Apply to net prices
    
    public function mathRound(float $price): float {
        if ($this->interval === 0.0) {
            return round($price, $this->decimals);
        }
        
        return round($price / $this->interval) * $this->interval;
    }
}
```

### 2.4 Promotion and Discount Processing

**Discount Calculation Workflow:**
```php
// DiscountCartProcessor implementation
1. Identify discount line items in cart
2. For each discount:
   a. Validate discount definition
   b. Check currency compatibility
   c. Calculate discount amount based on type:
      - Absolute: Fixed amount in specific currency
      - Percentage: Percentage of eligible price sum
   d. Apply maximum discount limits
   e. Handle minimum order value requirements
3. Create discount line items with negative prices
4. Update cart totals
5. Validate discount applications don't exceed cart value
```

### 2.5 Delivery Calculation

**Delivery Date Calculation:**
```php
// DeliveryDateService algorithm
1. For each line item:
   a. Get product delivery information
   b. Check stock status
   c. Calculate earliest delivery date:
      - If in stock: current date + delivery time
      - If restock: current date + restock time + delivery time
   d. Calculate latest delivery date (earliest + delivery time range)
2. Find latest delivery date across all items
3. Apply minimum delivery buffer (1 day)
4. Return DeliveryDate with earliest/latest dates
```

## 3. Service Interface Specification

### 3.1 CartService Interface

**Primary Service Interface:**
```php
interface CartServiceInterface {
    // Core Operations
    public function getCart(string $token, SalesChannelContext $context, string $cartBehavior = self::SALES_CHANNEL, bool $caching = true): Cart;
    public function createNew(string $token, string $cartBehavior = self::SALES_CHANNEL): Cart;
    public function recalculate(Cart $cart, SalesChannelContext $context): Cart;
    public function add(Cart $cart, $items, SalesChannelContext $context): Cart;
    public function remove(Cart $cart, array $ids, SalesChannelContext $context): Cart;
    public function changeQuantity(Cart $cart, string $id, int $quantity, SalesChannelContext $context): Cart;
    
    // Persistence Operations  
    public function save(Cart $cart, SalesChannelContext $context): void;
    public function delete(string $token, SalesChannelContext $context): void;
    
    // Utility Operations
    public function order(Cart $cart, SalesChannelContext $context, RequestDataBag $data): string;
}
```

**Method Specifications:**

**getCart() Method:**
```php
// Pre-conditions:
- $token must be valid UUID format
- $context must contain valid sales channel
- $cartBehavior must be valid behavior constant

// Post-conditions:  
- Returns valid Cart instance
- Cart is cached in memory for subsequent calls
- CartLoadedEvent dispatched if cart loaded from storage
- CartCreatedEvent dispatched if new cart created

// Exceptions:
- InvalidTokenException if token format invalid
- ContextException if sales channel context invalid
```

**add() Method:**
```php
// Pre-conditions:
- $cart must be valid Cart instance
- $items must be LineItem instance or array of LineItem instances
- Each LineItem must pass validation rules
- $context must contain valid customer and sales channel data

// Post-conditions:
- Line items added to cart or quantities merged if stackable
- Cart marked as modified  
- Cart recalculated with new items
- Appropriate events dispatched
- Returns updated Cart instance

// Exceptions:
- LineItemValidationException for invalid line items
- InsufficientPermissionException for price overrides
- CartLockedException if cart locked by another process
```

### 3.2 CartCalculator Interface

**Calculator Service Interface:**
```php  
interface CartCalculatorInterface {
    public function calculate(Cart $cart, SalesChannelContext $context): Cart;
}

// Implementation Requirements:
class CartCalculator implements CartCalculatorInterface {
    public function calculate(Cart $cart, SalesChannelContext $context): Cart {
        // 1. Load applicable rules
        $ruleLoaderResult = $this->cartRuleLoader->loadByToken($context, $cart->getToken());
        
        // 2. Process cart through pipeline
        $cart = $this->processor->process($context, $cart, $ruleLoaderResult->getCart(), $cart->getBehavior() ?? new CartBehavior());
        
        // 3. Generate context hash
        $cart->setHash($this->cartContextHasher->generate($context));
        
        // 4. Mark as unmodified
        $cart->markUnmodified();
        
        // 5. Set applied rule IDs
        $cart->setRuleIds($ruleLoaderResult->getMatchingRules()->getIds());
        
        return $cart;
    }
}
```

### 3.3 Processor Interface

**Main Processing Interface:**
```php
interface ProcessorInterface {
    public function process(SalesChannelContext $context, Cart $toCalculate, Cart $original, CartBehavior $behavior): Cart;
}

// Implementation Requirements:
class Processor implements ProcessorInterface {
    public function process(SalesChannelContext $context, Cart $toCalculate, Cart $original, CartBehavior $behavior): Cart {
        // 1. Initialize data collection
        $data = new CartDataCollection();
        
        // 2. Execute data collectors
        foreach ($this->collectors as $collector) {
            $collector->collect($data, $original, $context, $behavior);
        }
        
        // 3. Execute processors  
        foreach ($this->processors as $processor) {
            $processor->process($data, $toCalculate, $original, $context, $behavior);
        }
        
        // 4. Execute script hooks
        if ($behavior->isHookAware()) {
            $this->scriptExecutor->execute($data, $toCalculate, $context);
        }
        
        // 5. Validate cart
        $this->validator->validate($toCalculate, $context);
        
        // 6. Calculate final amounts  
        $toCalculate->setPrice($this->amountCalculator->calculate($toCalculate->getLineItems(), $toCalculate->getDeliveries(), $context));
        
        return $toCalculate;
    }
}
```

## 4. Integration Contract Specification

### 4.1 External Dependencies

**Product Service Integration:**
```php
interface ProductGatewayInterface {
    // Product data retrieval
    public function get(array $ids, SalesChannelContext $context): ProductCollection;
    public function search(array $ids, SalesChannelContext $context): ProductCollection;
    
    // Stock and availability
    public function getAvailableStock(string $productId, SalesChannelContext $context): int;
    public function isAvailable(string $productId, SalesChannelContext $context): bool;
}

// Required Product Entity Properties:
- id: string (UUID)
- productNumber: string  
- name: string
- price: PriceCollection
- tax: TaxEntity
- stock: int
- availableStock: int
- minPurchase: int
- maxPurchase: ?int
- purchaseSteps: int
- deliveryTime: DeliveryTimeEntity
- weight: ?float
- length: ?float  
- width: ?float
- height: ?float
- cover: ?MediaEntity
- customFields: ?array
```

**Rule Engine Integration:**
```php
interface RuleLoaderInterface {
    public function loadByToken(SalesChannelContext $context, string $cartToken): RuleLoaderResult;
}

class RuleLoaderResult {
    protected Cart $cart;                    // Rule-validated cart
    protected RuleCollection $matchingRules; // Applied rules
    
    public function getCart(): Cart;
    public function getMatchingRules(): RuleCollection;
}

// Required Rule Evaluation:
- Cart value rules (min/max amounts)
- Line item rules (product, quantity, price)  
- Customer rules (group, country, etc.)
- Sales channel rules
- Time-based rules
- Custom field rules
```

### 4.2 Event System Contracts

**Required Cart Events:**
```php
// Cart Lifecycle Events
class CartCreatedEvent extends Event {
    protected Cart $cart;
    protected SalesChannelContext $salesChannelContext;
}

class CartLoadedEvent extends Event {
    protected Cart $cart;
    protected SalesChannelContext $salesChannelContext;
}

class CartSavedEvent extends Event {
    protected Cart $cart;
    protected SalesChannelContext $salesChannelContext;
}

class CartDeletedEvent extends Event {
    protected string $token;
    protected SalesChannelContext $salesChannelContext;
}

// Line Item Events  
class BeforeLineItemAddedEvent extends Event {
    protected LineItem $lineItem;
    protected Cart $cart;
    protected SalesChannelContext $salesChannelContext;
}

class AfterLineItemAddedEvent extends Event {
    protected LineItem $lineItem;
    protected Cart $cart;
    protected SalesChannelContext $salesChannelContext;
}

class BeforeLineItemRemovedEvent extends Event {
    protected string $lineItemId;
    protected Cart $cart;
    protected SalesChannelContext $salesChannelContext;
}

class AfterLineItemRemovedEvent extends Event {
    protected string $lineItemId;
    protected Cart $cart;
    protected SalesChannelContext $salesChannelContext;
}

class BeforeLineItemQuantityChangedEvent extends Event {
    protected LineItem $lineItem;
    protected int $newQuantity;
    protected Cart $cart;
    protected SalesChannelContext $salesChannelContext;
}

class AfterLineItemQuantityChangedEvent extends Event {
    protected LineItem $lineItem;
    protected int $previousQuantity;
    protected Cart $cart;
    protected SalesChannelContext $salesChannelContext;
}
```

### 4.3 API Endpoint Specifications

**Store API Cart Endpoints:**

**GET /store-api/checkout/cart**
```php
// Headers Required:
- sw-context-token: string (sales channel context token)

// Response Format:
{
    "token": "string",           // Cart UUID token
    "lineItems": [...],          // Array of line item objects
    "price": {                   // Cart price object
        "netPrice": float,
        "totalPrice": float,
        "calculatedTaxes": [...],
        "taxRules": [...]
    },
    "deliveries": [...],         // Delivery objects
    "transactions": [...],       // Transaction objects
    "errors": [...]             // Validation error objects
}
```

**POST /store-api/checkout/cart/line-item**
```php
// Request Format:
{
    "items": [
        {
            "id": "string",              // Max 100 chars, pattern [a-zA-Z0-9-_.]
            "type": "string",            // LINE_ITEM_TYPE constant
            "referencedId": "string",    // Referenced entity ID
            "quantity": integer,         // Min 1
            "payload": {...}             // Optional payload data
        }
    ]
}

// Success Response: 200 with updated cart object
// Error Response: 400 with validation errors
```

**PATCH /store-api/checkout/cart/line-item**
```php
// Request Format:
{
    "items": [
        {
            "id": "string",              // Existing line item ID
            "quantity": integer          // New quantity
        }
    ]
}
```

**DELETE /store-api/checkout/cart/line-item**
```php
// Request Format:
{
    "ids": ["string", "string"]      // Array of line item IDs to remove
}
```

### 4.4 Database Schema Requirements

**Cart Storage Schema:**
```sql
CREATE TABLE `cart` (
    `token` VARCHAR(50) NOT NULL,           -- Cart UUID token
    `name` VARCHAR(500) NOT NULL,           -- Cart name/identifier  
    `cart_data_checksum` VARCHAR(32) NULL,  -- Data integrity checksum
    `payload` LONGTEXT NULL,                -- Serialized cart data
    `compressed` TINYINT(1) DEFAULT 0,      -- Compression flag
    `rule_ids` JSON NULL,                   -- Applied rule IDs
    `created_at` DATETIME(3) NOT NULL,      -- Creation timestamp
    PRIMARY KEY (`token`),
    KEY `idx.cart.created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Required Storage Operations:**
```php
interface CartPersisterInterface {
    public function load(string $token, SalesChannelContext $context): Cart;
    public function save(Cart $cart, SalesChannelContext $context): void;  
    public function delete(string $token, SalesChannelContext $context): void;
    public function replace(string $oldToken, string $newToken, SalesChannelContext $context): void;
}

// Redis Alternative Schema:
// Key: cart:{token}
// Value: compressed JSON cart data
// TTL: configurable (default 30 days)
```

## 5. Processing Pipeline Specification

### 5.1 Data Collection Pipeline

**CartDataCollectorInterface:**
```php
interface CartDataCollectorInterface {
    public function collect(CartDataCollection $data, Cart $original, SalesChannelContext $context, CartBehavior $behavior): void;
}

// Required Data Collectors:
1. ProductCartDataCollector - Fetches product data for product line items
2. ShippingMethodDataCollector - Loads available shipping methods  
3. PaymentMethodDataCollector - Loads available payment methods
4. PromotionDataCollector - Fetches promotion/discount data
5. CustomerDataCollector - Loads customer-specific data
```

**CartDataCollection Structure:**
```php
class CartDataCollection {
    protected array $data = [];              // Keyed storage for collected data
    
    public function set(string $key, $data): void;
    public function get(string $key, $default = null);
    public function has(string $key): bool;
    public function remove(string $key): void;
    
    // Specific data accessors
    public function getProducts(): ProductCollection;
    public function setProducts(ProductCollection $products): void;
    public function getShippingMethods(): ShippingMethodCollection; 
    public function setShippingMethods(ShippingMethodCollection $methods): void;
}
```

### 5.2 Processing Pipeline

**CartProcessorInterface:**
```php
interface CartProcessorInterface {
    public function process(CartDataCollection $data, Cart $toCalculate, Cart $original, SalesChannelContext $context, CartBehavior $behavior): void;
}

// Required Processors (in order):
1. ProductCartProcessor - Processes product line items
2. PromotionCartProcessor - Handles promotion line items
3. ContainerCartProcessor - Processes container line items
4. CreditCartProcessor - Handles credit line items  
5. CustomCartProcessor - Processes custom line items
6. DiscountCartProcessor - Applies discount calculations
7. DeliveryProcessor - Calculates delivery costs and dates
8. TransactionProcessor - Handles payment transactions
```

**ProductCartProcessor Implementation:**
```php
class ProductCartProcessor implements CartProcessorInterface {
    public function process(CartDataCollection $data, Cart $toCalculate, Cart $original, SalesChannelContext $context, CartBehavior $behavior): void {
        $products = $data->getProducts();
        $lineItems = $toCalculate->getLineItems()->filterType(LineItem::PRODUCT_LINE_ITEM_TYPE);
        
        foreach ($lineItems as $lineItem) {
            // 1. Validate product exists and is available
            $product = $products->get($lineItem->getReferencedId());
            if (!$product || !$product->getActive()) {
                if (!$behavior->hasPermission(CartBehavior::KEEP_INACTIVE_PRODUCT)) {
                    $toCalculate->getLineItems()->remove($lineItem->getId());
                    continue;
                }
            }
            
            // 2. Update line item data from product
            $this->updateLineItemFromProduct($lineItem, $product);
            
            // 3. Calculate price
            if (!$behavior->hasPermission(CartBehavior::SKIP_PRODUCT_RECALCULATION)) {
                $this->calculatePrice($lineItem, $product, $context);
            }
            
            // 4. Validate stock
            if (!$behavior->hasPermission(CartBehavior::SKIP_PRODUCT_STOCK_VALIDATION)) {
                $this->validateStock($lineItem, $product, $toCalculate);
            }
            
            // 5. Update delivery information
            $this->updateDeliveryInformation($lineItem, $product, $context);
        }
    }
}
```

### 5.3 Validation Pipeline

**CartValidatorInterface:**
```php
interface CartValidatorInterface {
    public function validate(Cart $cart, ErrorCollection $errors, SalesChannelContext $context): void;
}

// Required Validators:
1. ProductLineItemValidator - Validates product line items
2. CreditLineItemValidator - Validates credit items
3. CustomLineItemValidator - Validates custom items
4. DeliveryValidator - Validates delivery setup
5. PaymentMethodValidator - Validates payment methods
6. CartValidator - Validates cart-level rules
```

**Error Handling Requirements:**
```php
abstract class Error extends Exception {
    abstract public function getId(): string;           // Unique error identifier
    abstract public function getMessageKey(): string;   // Translation key
    abstract public function getLevel(): int;          // LEVEL_NOTICE/WARNING/ERROR
    abstract public function blockOrder(): bool;       // Prevents checkout
    abstract public function getParameters(): array;   // Error parameters
    public function isPersistent(): bool;              // Survives recalculation
}
```

**Validation Rules:**
- Stock validation with min/max purchase and steps
- Product availability and activation status
- Shipping method availability
- Price definition completeness
- Quantity constraints and parent-child relationships

### 5.4 State Management Requirements

**CartBehavior Configuration:**
```php
class CartBehavior {
    protected array $permissions = [];    // Feature permissions
    protected bool $hookAware = true;     // Enable/disable hooks
    protected bool $isRecalculation = false; // Recalculation context
    
    // Permission Constants
    const ALLOW_PRODUCT_PRICE_OVERWRITES = 'allowProductPriceOverwrites';
    const ALLOW_PRODUCT_LABEL_OVERWRITES = 'allowProductLabelOverwrites';
    const SKIP_PRODUCT_RECALCULATION = 'skipProductRecalculation';
    const SKIP_PRODUCT_STOCK_VALIDATION = 'skipProductStockValidation';
    const KEEP_INACTIVE_PRODUCT = 'keepInactiveProduct';
    const SKIP_DELIVERY_PRICE_RECALCULATION = 'skipDeliveryPriceRecalculation';
}
```

## 6. Implementation Guidelines

### 6.1 Critical Implementation Requirements

1. **Thread Safety:** Cart operations must be atomic with locking mechanism
2. **Performance:** Data collection must be batched and cached
3. **Precision:** All monetary calculations must use precise decimal arithmetic
4. **Validation:** All input must be validated before processing
5. **Error Handling:** All errors must be collected and categorized properly
6. **Event System:** All operations must dispatch appropriate events
7. **Caching:** Cart data must be efficiently cached and invalidated

### 6.2 Security Considerations

1. **Payload Protection:** Sensitive payload data must respect protection flags
2. **Rate Limiting:** Cart item additions must be rate limited by IP
3. **Input Validation:** All identifiers must be validated against patterns
4. **Serialization Security:** Cart serialization must clean sensitive data

### 6.3 Performance Requirements

1. **Data Fetching:** Batch product/shipping method requests
2. **Calculation Optimization:** Skip unnecessary recalculations when possible
3. **Memory Management:** Clean up data collections after processing
4. **Database Queries:** Use prepared statements and connection pooling

This specification provides the complete technical requirements for implementing a functionally equivalent Cart Service based on Shopware's current implementation. The external development team can use this specification to build a system that maintains full compatibility with Shopware's cart behavior, validation rules, and business logic.