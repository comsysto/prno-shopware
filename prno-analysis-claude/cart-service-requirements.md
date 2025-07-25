# Shopware Cart Service - Requirements and Specifications

## Executive Summary

The Shopware Cart Service is a comprehensive e-commerce cart management system built on Symfony framework, providing full lifecycle management for shopping carts, line items, pricing calculations, tax handling, delivery management, and order conversion. The system supports multi-currency, multi-language operations with robust validation, error handling, and event-driven architecture.

## 1. Functional Requirements

### 1.1 Cart Lifecycle Operations

#### 1.1.1 Cart Creation and Initialization
- **Requirement**: System shall create new cart instances with unique tokens
- **Implementation**: `CartFactory::createNew()` creates carts with UUID tokens
- **Data Structure**: Cart contains token, line items collection, errors collection, deliveries collection, transactions collection, price information
- **Default State**: New cart initialized with empty collections and zero price

#### 1.1.2 Cart Loading and Persistence
- **Requirement**: System shall load and persist carts across sessions
- **Implementation**: 
  - `CartPersister` handles database persistence with compression support
  - `RedisCartPersister` provides Redis-based storage option
  - Carts stored with token, payload (compressed), rule IDs, and timestamps
- **Persistence Strategy**: 
  - Automatic saving after modifications
  - Optional persistence based on `CartVerifyPersistEvent`
  - Cleanup mechanism for expired carts (configurable retention period)

#### 1.1.3 Cart Calculation and Processing
- **Requirement**: System shall recalculate cart totals, taxes, and deliveries when modified
- **Implementation**: 
  - `CartCalculator` performs full recalculation using rule loader
  - `Processor` manages calculation pipeline with collectors and processors
  - Context-aware calculations based on sales channel, customer, and currency
- **Calculation Pipeline**:
  1. Data collection from various sources
  2. Line item processing and validation
  3. Price calculation and tax computation
  4. Delivery calculation
  5. Rule application and validation
  6. Transaction processing

### 1.2 Line Item Management

#### 1.2.1 Line Item Types and Properties
- **Supported Types**:
  - `PRODUCT_LINE_ITEM_TYPE`: Physical/digital products
  - `CUSTOM_LINE_ITEM_TYPE`: Custom items with manual pricing
  - `CREDIT_LINE_ITEM_TYPE`: Credit/refund items
  - `PROMOTION_LINE_ITEM_TYPE`: Promotional discounts
  - `DISCOUNT_LINE_ITEM`: Discount applications
  - `CONTAINER_LINE_ITEM`: Container for grouped items

#### 1.2.2 Line Item Constraints and Validation
- **Identifier Requirements**:
  - Maximum length: 100 characters
  - Allowed characters: alphanumeric, dashes, underscores, dots only
  - Pattern validation: `/[^a-zA-Z0-9-_\.]/`
- **Quantity Constraints**:
  - Minimum quantity: 1
  - Stackable items allow quantity changes
  - Non-stackable items fixed at quantity 1
  - Child items quantity must be multiple of parent quantity

#### 1.2.3 Line Item Operations
- **Add Operation**: 
  - Rate limiting per IP address for add operations
  - Duplicate detection and merging for stackable items
  - Event dispatching: `BeforeLineItemAddedEvent`, `AfterLineItemAddedEvent`
- **Update Operation**:
  - Quantity modifications for stackable items
  - Payload updates with validation
  - Price definition updates (requires permissions)
- **Remove Operation**:
  - Removability check before deletion
  - Cascade removal for child items
  - Event dispatching: `BeforeLineItemRemovedEvent`, `AfterLineItemRemovedEvent`

### 1.3 Price Calculations and Tax Handling

#### 1.3.1 Price Calculation Types
- **Quantity Price Definition**: Unit price × quantity with tax rules
- **Absolute Price Definition**: Fixed amount with currency support
- **Percentage Price Definition**: Percentage-based pricing
- **Currency Price Definition**: Multi-currency price support

#### 1.3.2 Tax Calculation Rules
- **Tax States**:
  - `TAX_STATE_GROSS`: Prices include tax
  - `TAX_STATE_NET`: Prices exclude tax  
  - `TAX_STATE_FREE`: Tax-free pricing
- **Tax Calculation**:
  - Gross-to-net and net-to-gross conversion
  - Multiple tax rate support per item
  - Tax rule collections with percentage-based distribution
  - Rounding according to currency precision

#### 1.3.3 Price Rounding and Precision
- **Implementation**: `CashRounding` class handles currency-specific rounding
- **Precision**: FloatComparator ensures consistent float handling
- **Rounding Rules**: Configurable per currency and tax calculation

### 1.4 Promotion and Discount Processing

#### 1.4.1 Promotion Types and Application
- **Discount Types**: Absolute discounts, percentage discounts
- **Application Rules**: Rule-based promotion eligibility
- **Stacking Rules**: Multiple promotion handling and conflicts
- **Validation**: Promotion code validation and usage limits

#### 1.4.2 Discount Calculation
- **Price Collection Requirements**: Absolute discounts require price collections
- **Currency Support**: Multi-currency discount application
- **Error Handling**: Comprehensive validation with specific error codes

### 1.5 Shipping and Delivery Calculations

#### 1.5.1 Delivery Information Management
- **Delivery Time Calculation**: Based on product availability and shipping method
- **Stock Awareness**: In-stock vs. restock delivery dates
- **Delivery Positions**: Individual item delivery requirements
- **Shipping Location**: Customer address-based delivery calculation

#### 1.5.2 Delivery Date Calculation
- **Algorithm**: Latest delivery date determination across all items
- **Restock Handling**: Additional days for out-of-stock items
- **Date Buffering**: Minimum one-day buffer for same-day calculations

### 1.6 Customer Context and Personalization

#### 1.6.1 Customer-Specific Features
- **Customer Comments**: Free-text comments associated with cart
- **Affiliate Tracking**: Affiliate code support for referral tracking
- **Campaign Tracking**: Campaign code support for marketing attribution
- **Customer Login State**: Authentication-aware cart operations

#### 1.6.2 Multi-Currency and Multi-Language Support
- **Currency Conversion**: Real-time price conversion based on sales channel
- **Language Support**: Localized error messages and content
- **Regional Tax Rules**: Country/region-specific tax calculations

## 2. Business Rules

### 2.1 Cart Validation Rules

#### 2.1.1 Line Item Validation
- Line items must have valid identifiers (length and character restrictions)
- Quantities must be positive integers
- Stackable items can have quantity > 1, non-stackable fixed at 1
- Child items quantity must be multiple of parent quantity
- Payload values must be scalar or array types only

#### 2.1.2 Price Validation
- All line items must have valid price definitions
- Price definitions must match expected types
- Currency-specific prices required for multi-currency support
- Tax rates must be valid percentages

#### 2.1.3 Cart State Validation
- Empty carts cannot be converted to orders
- All validation errors must be resolved before order placement
- Customer must be logged in for order placement (configurable)

### 2.2 Line Item Constraints and Limits

#### 2.2.1 Identifier Constraints
- **Maximum Length**: 100 characters
- **Character Set**: Alphanumeric, dash, underscore, dot only
- **Uniqueness**: Identifiers must be unique within cart scope

#### 2.2.2 Quantity Rules
- **Minimum Quantity**: 1 for all line items
- **Stackability**: Determined by line item type and configuration
- **Child Item Rules**: Child quantities must align with parent quantities

#### 2.2.3 Payload Restrictions
- **Data Types**: Only scalar values (string, int, float, bool) and arrays allowed
- **Protection**: Payload keys can be marked as protected (not serialized)
- **Size Limits**: Implicit limits through database column constraints

### 2.3 Pricing Rules and Calculations

#### 2.3.1 Tax Calculation Rules
- Tax rates applied as percentages of base price
- Multiple tax rules can apply to single line item
- Tax distribution based on rule percentages
- Rounding applied per currency configuration

#### 2.3.2 Discount Application Rules
- Discounts applied after base price calculation
- Percentage discounts calculated on eligible price amounts
- Absolute discounts require compatible currency definitions
- Discount stacking rules prevent conflicting applications

### 2.4 Delivery and Shipping Rules

#### 2.4.1 Shipping Cost Awareness
- Line items can be marked as shipping-cost-aware or exempt
- Exempt items don't contribute to delivery calculations
- Container items inherit shipping rules from children

#### 2.4.2 Delivery Date Rules
- Delivery dates calculated from latest required item
- Stock availability affects delivery timing
- Restock items add additional delivery days
- Minimum one-day delivery window enforced

## 3. Non-Functional Requirements

### 3.1 Performance Requirements

#### 3.1.1 Caching and Persistence
- **In-Memory Caching**: Cart instances cached in service layer during request
- **Database Persistence**: Compressed serialization for storage efficiency
- **Redis Support**: Optional Redis backend for high-performance scenarios
- **Rule Caching**: `CachedRuleLoader` provides rule result caching

#### 3.1.2 Scalability Features
- **Cart Locking**: `CartLocker` prevents concurrent modification conflicts
- **Rate Limiting**: Add operations rate-limited per IP address
- **Batch Operations**: Support for multiple line item operations
- **Compression**: Cart payload compression reduces storage requirements

### 3.2 Security Considerations

#### 3.2.1 Access Control
- **Permission System**: Cart behavior includes permission checking
- **Price Override Protection**: Product price modifications require specific permissions
- **Token-Based Access**: Cart access controlled via unique tokens
- **Customer Authentication**: Order placement requires authenticated customers

#### 3.2.2 Data Protection
- **Payload Protection**: Sensitive payload data can be marked as protected
- **Input Validation**: Comprehensive validation prevents malicious input
- **Error Handling**: Secure error messages without data exposure

### 3.3 Data Consistency and Integrity

#### 3.3.1 Transaction Management
- **Cart Locking**: Prevents concurrent modifications
- **Atomic Operations**: Cart updates are atomic at service level
- **Rollback Capability**: Error conditions don't persist invalid states
- **State Tracking**: Modification flags track cart changes

#### 3.3.2 Data Validation
- **Schema Validation**: Strong typing throughout the system
- **Business Rule Enforcement**: Comprehensive validation at multiple layers
- **Error Collection**: All validation errors collected and reported together

### 3.4 Integration Capabilities

#### 3.4.1 Event System Integration
- **Comprehensive Events**: 20+ events for cart operations
- **Before/After Hooks**: Pre and post operation event dispatching
- **State Change Events**: Cart modification and persistence events
- **Custom Event Handling**: Extensible event system for custom logic

#### 3.4.2 External System Interfaces
- **REST API**: Complete Store API for cart operations
- **Hook System**: Script execution hooks for custom business logic
- **Rule Engine**: Deep integration with Shopware rule system
- **Tax Provider**: External tax calculation service integration

## 4. Data Requirements

### 4.1 Cart Data Structure

#### 4.1.1 Core Cart Attributes
```php
- token: string (unique identifier)
- lineItems: LineItemCollection
- errors: ErrorCollection  
- deliveries: DeliveryCollection
- transactions: TransactionCollection
- price: CartPrice
- modified: boolean
- customerComment: ?string
- affiliateCode: ?string
- campaignCode: ?string
- source: ?string (for multi-cart scenarios)
- hash: ?string (content hash)
- errorHash: string
- data: ?CartDataCollection (transient calculation data)
- ruleIds: array<string>
- behavior: ?CartBehavior
```

#### 4.1.2 Line Item Properties
```php
- id: string (max 100 chars, alphanumeric + -_.)
- type: string (product, custom, credit, promotion, discount, container)
- referencedId: ?string
- quantity: int (>= 1)
- label: ?string
- description: ?string
- payload: array<string, mixed>
- priceDefinition: ?PriceDefinitionInterface
- price: ?CalculatedPrice
- good: boolean
- cover: ?MediaEntity
- deliveryInformation: ?DeliveryInformation
- children: LineItemCollection
- requirement: ?Rule
- removable: boolean
- stackable: boolean
- quantityInformation: ?QuantityInformation
- modified: boolean
- shippingCostAware: boolean
- dataTimestamp: ?\DateTimeInterface
- dataContextHash: ?string
- uniqueIdentifier: string
- states: array<int, string>
- modifiedByApp: boolean
```

### 4.2 Price and Tax Data Models

#### 4.2.1 Cart Price Structure
```php
- netPrice: float
- totalPrice: float  
- positionPrice: float
- rawTotal: float
- calculatedTaxes: CalculatedTaxCollection
- taxRules: TaxRuleCollection
- taxStatus: string (gross, net, tax-free)
```

#### 4.2.2 Tax Calculation Data
```php
CalculatedTax:
- tax: float
- taxRate: float
- price: float

TaxRule:
- taxRate: float
- percentage: float
```

### 4.3 Delivery and Shipping Data

#### 4.3.1 Delivery Information
```php
- weight: ?float
- height: ?float
- width: ?float
- length: ?float
- releaseDate: ?\DateTimeInterface
- restockTime: ?int
- deliveryTime: ?DeliveryTime
- stock: int
```

#### 4.3.2 Delivery Time and Date
```php
DeliveryTime:
- min: int
- max: int
- unit: string
- name: string

DeliveryDate:
- earliest: \DateTimeInterface
- latest: \DateTimeInterface
```

### 4.4 Persistence Requirements

#### 4.4.1 Database Schema
- **Cart Table**: token (PK), payload (compressed), rule_ids, compressed flag, created_at
- **Compression**: Support for gzip and other compression methods
- **Retention**: Configurable cleanup of old cart data
- **Indexing**: Token-based primary access pattern

#### 4.4.2 Serialization Requirements
- **Cart Serialization**: Custom serialization with data cleanup
- **Compression Support**: Multiple compression algorithms
- **Version Compatibility**: Forward/backward compatibility for cart data
- **Error Handling**: Graceful handling of corrupted cart data

## 5. Integration Requirements

### 5.1 Product Catalog Integration

#### 5.1.1 Product Data Requirements
- Product availability and stock information
- Pricing data with currency support
- Delivery information and constraints
- Product properties and custom fields
- Media information for line item display

#### 5.1.2 Product Validation
- Product existence validation during cart operations
- Stock availability checking
- Price validation and override permissions
- Product property-based rule evaluation

### 5.2 Customer Service Integration

#### 5.2.1 Customer Context
- Customer authentication state
- Customer-specific pricing rules
- Address information for delivery calculation
- Customer group-based permissions

#### 5.2.2 Customer Data Usage
- Personalized pricing calculation
- Delivery location determination
- Tax calculation based on customer address
- Customer-specific promotions and discounts

### 5.3 Rule Engine Integration

#### 5.3.1 Cart-Level Rules
- Cart amount rules (minimum/maximum thresholds)
- Cart weight and volume rules
- Goods count and price rules
- Shipping method and payment method rules
- Customer and sales channel rules

#### 5.3.2 Line Item Rules
- Product-specific rules (category, manufacturer, properties)
- Line item quantity and price rules
- Stock and availability rules
- Temporal rules (creation date, release date)
- Custom field-based rules

### 5.4 Event System Integration

#### 5.4.1 Cart Events
- `CartCreatedEvent`, `CartLoadedEvent`, `CartSavedEvent`, `CartDeletedEvent`
- `CartChangedEvent`, `CartMergedEvent`
- `CartVerifyPersistEvent`, `CartBeforeSerializationEvent`

#### 5.4.2 Line Item Events
- `BeforeLineItemAddedEvent`, `AfterLineItemAddedEvent`
- `BeforeLineItemRemovedEvent`, `AfterLineItemRemovedEvent`
- `BeforeLineItemQuantityChangedEvent`, `AfterLineItemQuantityChangedEvent`

### 5.5 External System Interfaces

#### 5.5.1 Tax Provider Integration
- External tax calculation service support
- Tax provider registry for multiple providers
- Tax adjustment and override capabilities
- Error handling for tax service failures

#### 5.5.2 Payment and Shipping Integration
- Payment method validation and rules
- Shipping method calculation and validation
- Delivery time calculation integration
- Cost calculation service integration

## 6. API Requirements

### 6.1 Store API Endpoints

#### 6.1.1 Cart Operations
- `GET /store-api/checkout/cart` - Load current cart
- `POST /store-api/checkout/cart/line-item` - Add line item to cart
- `PATCH /store-api/checkout/cart/line-item` - Update line item quantity
- `DELETE /store-api/checkout/cart/line-item` - Remove line item from cart
- `DELETE /store-api/checkout/cart` - Clear entire cart

#### 6.1.2 Request/Response Format
- **Request Format**: JSON with proper content-type headers
- **Response Format**: JSON-API compliant structure
- **Error Format**: Standardized error response with codes and messages
- **Authentication**: Context token-based authentication

### 6.2 Admin API Endpoints

#### 6.2.1 Cart Management
- Full CRUD operations for cart administration
- Bulk operations for line item management
- Cart analytics and reporting endpoints
- Cart rule testing and validation endpoints

#### 6.2.2 Security Requirements
- **Authentication**: JWT-based authentication required
- **Authorization**: Role-based access control (ACL)
- **Rate Limiting**: Admin operations rate-limited per user
- **Audit Logging**: All administrative actions logged

## 7. Error Handling Requirements

### 7.1 Error Types and Codes

#### 7.1.1 Cart-Level Errors
- `CART-1`: General cart validation error
- `CART-2`: Cart empty error
- `CART-3`: Cart token invalid error
- `CART-4`: Cart persistence error
- `CART-5`: Cart calculation error

#### 7.1.2 Line Item Errors
- `CHECKOUT_CART_LINE_ITEM_NOT_FOUND`: Line item not found
- `CHECKOUT_CART_LINE_ITEM_NOT_STACKABLE`: Item not stackable
- `CHECKOUT_CART_LINE_ITEM_NOT_REMOVABLE`: Item cannot be removed
- `CHECKOUT_CART_INVALID_LINE_ITEM_QUANTITY`: Invalid quantity
- `CHECKOUT_CART_INVALID_LINE_ITEM_ID`: Invalid line item identifier

#### 7.1.3 Price and Tax Errors
- `CHECKOUT_CART_INSUFFICIENT_PERMISSION`: Permission denied for price override
- `CHECKOUT_CART_INVALID_PRICE_DEFINITION`: Invalid price definition
- `CHECKOUT_CART_TAX_CALCULATION_FAILED`: Tax calculation error

### 7.2 Error Response Format

#### 7.2.1 Error Structure
```json
{
  "errors": [
    {
      "code": "CHECKOUT_CART_LINE_ITEM_NOT_FOUND",
      "status": "400",
      "title": "Line item not found",
      "detail": "Line item with id 'invalid-id' not found in cart",
      "source": {
        "pointer": "/lineItems/invalid-id"
      }
    }
  ]
}
```

#### 7.2.2 Error Handling Strategy
- **Collection Strategy**: All validation errors collected before response
- **Localization**: Error messages localized based on request context
- **Detail Level**: Appropriate detail level based on user type (customer vs admin)
- **Recovery Information**: Guidance on how to resolve errors when applicable

## 8. Performance and Scalability Specifications

### 8.1 Performance Metrics

#### 8.1.1 Response Time Requirements
- **Cart Load**: < 100ms for cached carts
- **Line Item Add**: < 200ms including calculation
- **Cart Calculation**: < 500ms for complex carts (100+ items)
- **Cart Persistence**: < 50ms for Redis, < 200ms for database

#### 8.1.2 Throughput Requirements
- **Concurrent Users**: Support 1000+ concurrent cart operations
- **Cart Operations**: 10,000+ operations per minute per server
- **Storage Efficiency**: 90%+ compression ratio for cart persistence

### 8.2 Scalability Features

#### 8.2.1 Horizontal Scaling
- **Stateless Design**: Cart service fully stateless with external persistence
- **Load Balancing**: Support for load balancing across multiple instances
- **Cache Distribution**: Redis cluster support for distributed caching
- **Database Scaling**: Read replica support for cart data access

#### 8.2.2 Resource Optimization
- **Memory Usage**: Efficient object lifecycle management
- **CPU Usage**: Optimized calculation algorithms
- **Storage Usage**: Compressed persistence with cleanup strategies
- **Network Usage**: Minimal data transfer through compression and caching

## Conclusion

The Shopware Cart Service represents a sophisticated, enterprise-grade e-commerce cart management system with comprehensive functionality covering all aspects of shopping cart operations. The system provides robust validation, flexible pricing, comprehensive tax handling, and extensive integration capabilities while maintaining high performance and security standards. The architecture supports complex business scenarios including multi-currency operations, promotional campaigns, and custom business rules while providing extensive extensibility through events and hooks.

### Key Requirements Summary

1. **Functional Completeness**: Full cart lifecycle with complex line item management
2. **Business Rule Flexibility**: Comprehensive validation and rule system
3. **Performance Excellence**: Caching, compression, and optimization features
4. **Security Robustness**: Permission system, input validation, and secure operations
5. **Integration Readiness**: Event system, API endpoints, and external service integration
6. **Scalability Support**: Stateless design with distributed caching capabilities
7. **Error Handling**: Comprehensive error management with detailed feedback
8. **Data Integrity**: Strong typing, validation, and consistency mechanisms

This requirements specification serves as the definitive guide for understanding the current Shopware Cart Service functionality and provides the foundation for any system rewrite or migration efforts.