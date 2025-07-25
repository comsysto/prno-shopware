# Shopware Cart Service - C4 Code Diagram (PlantUML)

This document contains the C4 Code diagram for the Cart Service within the Shopware Core Backend API using PlantUML notation, showing the key classes, interfaces, and their relationships.

## PlantUML Code Diagram

```plantuml
@startuml Shopware-Cart-Service-Code
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Component.puml

LAYOUT_WITH_LEGEND()

title Code diagram for Shopware Cart Service

' External Dependencies
System_Ext(product_service, "Product Service", "Product catalog and pricing")
System_Ext(customer_service, "Customer Service", "Customer context and data")
System_Ext(rule_engine, "Rule Engine", "Business rules and validation")
System_Ext(event_dispatcher, "Event Dispatcher", "Event system")
ContainerDb_Ext(redis_cache, "Redis Cache", "Cart persistence")
ContainerDb_Ext(database, "Database", "Cart data storage")

Container_Boundary(cart_service, "Cart Service") {
    
    ' Core Domain Classes
    Component(cart_entity, "Cart", "PHP Class", "Main cart aggregate root with token, lineItems, price, deliveries, and errors collections")
    Component(line_item, "LineItem", "PHP Class", "Individual cart item with type, quantity, price, payload, and nested children support")
    Component(line_item_collection, "LineItemCollection", "PHP Collection Class", "Manages multiple line items with filtering, calculation, and manipulation methods")
    Component(calculated_price, "CalculatedPrice", "PHP Value Object", "Final calculated price with unit price, quantity, total amount, and tax details")
    Component(cart_price, "CartPrice", "PHP Value Object", "Complete cart pricing with net, gross, position prices, and tax calculations")
    
    ' Service Layer Classes
    Component(cart_service_class, "CartService", "PHP Service Class", "Main cart facade managing lifecycle: create, load, modify, persist with in-memory caching")
    Component(cart_calculator, "CartCalculator", "PHP Service Class", "Recalculates modified carts using rule loader and generates cart hash for validation")
    Component(processor, "Processor", "PHP Service Class", "Core cart processing engine orchestrating data collectors and processors in pipeline")
    Component(cart_factory, "CartFactory", "PHP Factory Class", "Creates new cart instances and dispatches CartCreatedEvent")
    
    ' Persistence Layer
    Component(abstract_persister, "AbstractCartPersister", "PHP Abstract Class", "Template method pattern for cart persistence with shouldPersist() validation")
    Component(redis_persister, "RedisCartPersister", "PHP Class", "Redis-based cart persistence with compression and serialization optimization")
    Component(cart_compressor, "CartCompressor", "PHP Service Class", "Compresses cart data for efficient storage and network transfer")
    Component(serialization_cleaner, "CartSerializationCleaner", "PHP Service Class", "Cleans cart data for serialization removing circular references")
    
    ' Calculation Engine
    Component(amount_calculator, "AmountCalculator", "PHP Service Class", "Main price calculation coordinator handling gross/net/free tax states")
    Component(tax_calculator, "TaxCalculator", "PHP Service Class", "Core tax calculation logic for gross/net conversions and tax rule application")
    Component(quantity_calculator, "QuantityPriceCalculator", "PHP Service Class", "Handles quantity-based pricing with scale pricing and customer group rates")
    Component(percentage_calculator, "PercentagePriceCalculator", "PHP Service Class", "Percentage-based discount calculations with precision handling")
    Component(currency_calculator, "CurrencyPriceCalculator", "PHP Service Class", "Currency-specific calculations with exchange rates and rounding")
    Component(absolute_calculator, "AbsolutePriceCalculator", "PHP Service Class", "Fixed amount calculations for surcharges and absolute discounts")
    
    ' Price Definition Classes
    Component(price_definition_interface, "PriceDefinitionInterface", "PHP Interface", "Abstract contract for different price calculation types")
    Component(quantity_price_def, "QuantityPriceDefinition", "PHP Value Object", "Quantity-based price definition with unit price and tax rules")
    Component(percentage_price_def, "PercentagePriceDefinition", "PHP Value Object", "Percentage-based price definition for discounts and surcharges")
    Component(currency_price_def, "CurrencyPriceDefinition", "PHP Value Object", "Currency-specific price definition with exchange rate handling")
    Component(absolute_price_def, "AbsolutePriceDefinition", "PHP Value Object", "Fixed amount price definition for absolute pricing")
    
    ' Processing Pipeline
    Component(processor_interface, "CartProcessorInterface", "PHP Interface", "Contract for cart processors handling specific line item types and calculations")
    Component(product_processor, "ProductCartProcessor", "PHP Service Class", "Processes product line items with pricing, availability, and validation")
    Component(discount_processor, "DiscountCartProcessor", "PHP Service Class", "Handles discount line items and promotion calculations")
    Component(delivery_processor, "DeliveryProcessor", "PHP Service Class", "Manages shipping calculations and delivery method selection")
    Component(credit_processor, "CreditCartProcessor", "PHP Service Class", "Processes credit line items for refunds and store credit")
    Component(custom_processor, "CustomCartProcessor", "PHP Service Class", "Handles custom line items and user-defined products")
    
    ' Data Collection
    Component(collector_interface, "CartDataCollectorInterface", "PHP Interface", "Contract for collecting external data needed for cart processing")
    Component(validator, "Validator", "PHP Service Class", "Orchestrates multiple cart validation rules and error collection")
    Component(validator_interface, "CartValidatorInterface", "PHP Interface", "Contract for individual cart validation rules")
    
    ' Rule Integration
    Component(cart_rule_loader, "CartRuleLoader", "PHP Service Class", "Loads and applies business rules to cart with context evaluation")
    Component(rule_loader_result, "RuleLoaderResult", "PHP Value Object", "Contains validated cart with matching rules and applied discounts")
    
    ' Factory Registry
    Component(factory_registry, "LineItemFactoryRegistry", "PHP Registry Class", "Registry for different line item factories with type-based resolution")
    Component(factory_interface, "LineItemFactoryInterface", "PHP Interface", "Contract for creating specific line item types")
    Component(product_factory, "ProductLineItemFactory", "PHP Factory Class", "Creates product line items with catalog integration")
    Component(custom_factory, "CustomLineItemFactory", "PHP Factory Class", "Creates custom line items for user-defined products")
    Component(credit_factory, "CreditLineItemFactory", "PHP Factory Class", "Creates credit line items for refunds and adjustments")
    Component(promotion_factory, "PromotionLineItemFactory", "PHP Factory Class", "Creates promotion line items for discounts and offers")
}

' Core Domain Relationships
Rel(cart_entity, line_item_collection, "contains", "1:1")
Rel(line_item_collection, line_item, "manages", "1:N")
Rel(line_item, calculated_price, "has", "1:1")
Rel(line_item, line_item_collection, "children", "1:1")
Rel(cart_entity, cart_price, "totalPrice", "1:1")

' Service Layer Relationships
Rel(cart_service_class, cart_calculator, "uses", "")
Rel(cart_service_class, cart_factory, "creates carts", "")
Rel(cart_service_class, abstract_persister, "persists", "")
Rel(cart_calculator, processor, "processes", "")
Rel(cart_calculator, cart_rule_loader, "loads rules", "")

' Persistence Relationships
Rel(redis_persister, abstract_persister, "extends", "")
Rel(redis_persister, cart_compressor, "compresses", "")
Rel(redis_persister, serialization_cleaner, "cleans", "")
Rel(abstract_persister, cart_entity, "persists", "")

' Calculation Engine Relationships
Rel(processor, amount_calculator, "calculates totals", "")
Rel(amount_calculator, tax_calculator, "calculates taxes", "")
Rel(amount_calculator, quantity_calculator, "quantity pricing", "")
Rel(amount_calculator, percentage_calculator, "percentage pricing", "")
Rel(amount_calculator, currency_calculator, "currency pricing", "")
Rel(amount_calculator, absolute_calculator, "absolute pricing", "")

' Price Definition Relationships
Rel(quantity_price_def, price_definition_interface, "implements", "")
Rel(percentage_price_def, price_definition_interface, "implements", "")
Rel(currency_price_def, price_definition_interface, "implements", "")
Rel(absolute_price_def, price_definition_interface, "implements", "")
Rel(line_item, price_definition_interface, "uses", "")

' Processing Pipeline Relationships
Rel(processor, processor_interface, "orchestrates", "1:N")
Rel(product_processor, processor_interface, "implements", "")
Rel(discount_processor, processor_interface, "implements", "")
Rel(delivery_processor, processor_interface, "implements", "")
Rel(credit_processor, processor_interface, "implements", "")
Rel(custom_processor, processor_interface, "implements", "")

Rel(processor, collector_interface, "collects data", "1:N")
Rel(processor, validator, "validates", "")
Rel(validator, validator_interface, "uses", "1:N")

' Rule Integration Relationships
Rel(cart_rule_loader, rule_loader_result, "returns", "")
Rel(cart_rule_loader, cart_entity, "processes", "")

' Factory Registry Relationships
Rel(factory_registry, factory_interface, "manages", "1:N")
Rel(product_factory, factory_interface, "implements", "")
Rel(custom_factory, factory_interface, "implements", "")
Rel(credit_factory, factory_interface, "implements", "")
Rel(promotion_factory, factory_interface, "implements", "")
Rel(factory_registry, line_item, "creates", "")

' External Dependencies
Rel(cart_service_class, event_dispatcher, "dispatches events", "")
Rel(product_processor, product_service, "fetches products", "")
Rel(cart_rule_loader, rule_engine, "evaluates rules", "")
Rel(cart_calculator, customer_service, "context", "")
Rel(redis_persister, redis_cache, "stores/retrieves", "")
Rel(cart_service_class, database, "backup storage", "")

' Layout positioning
Lay_D(cart_entity, cart_service_class)
Lay_D(cart_service_class, processor)
Lay_D(processor, amount_calculator)
Lay_R(cart_entity, line_item)
Lay_R(line_item, calculated_price)
Lay_R(processor, product_processor)
Lay_L(cart_service_class, redis_persister)

@enduml
```

## Code Architecture Description

### **Core Domain Model**

#### **Cart Entity**
- **Type**: Aggregate Root
- **Key Responsibilities**:
  - Maintains cart state with unique token identification
  - Contains collections: `LineItemCollection`, `DeliveryCollection`, `ErrorCollection`
  - Manages cart-level pricing through `CartPrice`
  - Tracks modification state and validation errors
- **Key Methods**:
  - `add(LineItem)`, `remove(string $id)`, `get(string $id)`
  - `getPrice()`, `getErrors()`, `getDeliveries()`
  - `markModified()`, `markUnmodified()`

#### **LineItem Entity**
- **Type**: Entity with Value Object characteristics
- **Key Properties**:
  - `id`, `type` (PRODUCT, CUSTOM, CREDIT, PROMOTION, DISCOUNT, CONTAINER)
  - `quantity`, `price` (CalculatedPrice), `payload` (flexible data)
  - `children` (LineItemCollection) for nested items
- **Business Logic**:
  - Supports complex product configurations through payload
  - Handles nested line items for bundles and containers
  - Maintains delivery information and requirements

#### **CalculatedPrice Value Object**
- **Type**: Immutable Value Object
- **Components**:
  - `unitPrice`, `quantity`, `totalPrice`
  - `calculatedTaxes` (TaxCollection)
  - `taxRules` (TaxRuleCollection)
- **Calculation Methods**:
  - Tax calculation based on gross/net/free states
  - Currency rounding according to context rules

### **Service Layer Architecture**

#### **CartService**
- **Pattern**: Facade Pattern
- **Responsibilities**:
  - Public API for cart operations: create, load, add, remove, recalculate
  - In-memory cart caching by token for performance
  - Delegates complex operations to specialized services
- **Integration Points**:
  - Route classes for API operations (`CartLoadRoute`, `CartItemAddRoute`)
  - Event dispatching for cart lifecycle events
  - Context-aware operations with `SalesChannelContext`

#### **CartCalculator**
- **Pattern**: Calculator Pattern
- **Algorithm**:
  1. Load applicable business rules via `CartRuleLoader`
  2. Process cart through `Processor` pipeline
  3. Generate cart hash for change detection
  4. Mark cart as unmodified after successful calculation
- **Performance Optimizations**:
  - Hash-based change detection to avoid unnecessary calculations
  - Rule caching and optimization

#### **Processor**
- **Pattern**: Pipeline Pattern
- **Processing Steps**:
  1. **Data Collection**: Execute `CartDataCollectorInterface[]` to gather external data
  2. **Processing**: Execute `CartProcessorInterface[]` for calculations and modifications
  3. **Script Execution**: Custom script hooks for business logic extensions
  4. **Validation**: Execute `CartValidatorInterface[]` for business rule validation
  5. **Final Calculation**: `AmountCalculator` for total price computation

### **Persistence Layer**

#### **AbstractCartPersister**
- **Pattern**: Template Method Pattern
- **Template Algorithm**:
  1. Check `shouldPersist(Cart, SalesChannelContext)` conditions
  2. Execute concrete persistence implementation
  3. Handle persistence errors and cleanup
- **Persistence Conditions**:
  - Cart modification state
  - Customer authentication status
  - Cart content validation

#### **RedisCartPersister**
- **Pattern**: Concrete Strategy
- **Optimization Features**:
  - Cart compression using `CartCompressor`
  - Serialization cleaning via `CartSerializationCleaner`
  - TTL-based automatic cleanup
  - Bulk operations for performance

### **Calculation Engine**

#### **AmountCalculator**
- **Pattern**: Coordinator Pattern
- **Tax State Handling**:
  - `GROSS`: Calculate net from gross prices
  - `NET`: Calculate gross from net prices  
  - `FREE`: Tax-free calculations
- **Calculation Pipeline**:
  1. Process line item prices
  2. Apply quantity-based calculations
  3. Handle percentage and absolute adjustments
  4. Calculate final cart totals with tax

#### **Price Calculators**
- **Strategy Pattern Implementation**:
  - `QuantityPriceCalculator`: Volume pricing, customer group rates
  - `PercentagePriceCalculator`: Relative discounts and surcharges
  - `CurrencyPriceCalculator`: Multi-currency with exchange rates
  - `AbsolutePriceCalculator`: Fixed amount adjustments

### **Processing Pipeline Components**

#### **Cart Processors**
- **Chain of Responsibility Pattern**:
  - `ProductCartProcessor`: Product catalog integration, pricing, availability
  - `DiscountCartProcessor`: Promotion and discount calculations
  - `DeliveryProcessor`: Shipping method selection and cost calculation
  - `CreditCartProcessor`: Store credit and refund handling
  - `CustomCartProcessor`: User-defined custom products

#### **Validation System**
- **Composite Pattern**:
  - `Validator` orchestrates multiple `CartValidatorInterface` implementations
  - Each validator focuses on specific business rules
  - Accumulates validation errors in `ErrorCollection`

### **Integration and Extension Points**

#### **Rule Engine Integration**
- **CartRuleLoader**: 
  - Loads applicable business rules based on cart context
  - Evaluates rule conditions against current cart state
  - Returns `RuleLoaderResult` with matched rules and modifications

#### **Factory System**
- **Abstract Factory Pattern**:
  - `LineItemFactoryRegistry` manages type-specific factories
  - Each factory (`ProductLineItemFactory`, `CustomLineItemFactory`, etc.) 
  - Handles creation logic for specific line item types
  - Integrates with external services (product catalog, pricing)

### **Cross-Cutting Concerns**

#### **Event Integration**
- **Domain Events**:
  - `CartCreatedEvent`, `CartLoadedEvent`, `CartSavedEvent`
  - `BeforeLineItemAddedEvent`, `AfterLineItemAddedEvent`
  - `CartDeletedEvent`, `CartCalculatedEvent`

#### **Performance Optimizations**:
- In-memory caching in `CartService`
- Redis-based persistence with compression
- Hash-based change detection
- Lazy loading of associated data

#### **Extensibility**:
- Plugin hooks in processing pipeline
- Custom script execution points
- Interface-based dependency injection
- Event-driven side effects

This code diagram reveals the sophisticated architecture of Shopware's cart system, showing how it handles complex e-commerce scenarios including multi-currency pricing, tax calculations, promotions, shipping, and extensibility requirements. The design follows solid object-oriented principles with clear separation of concerns and high extensibility.