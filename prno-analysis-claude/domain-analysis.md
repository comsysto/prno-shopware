# Shopware Domain Architecture Analysis

This document provides a comprehensive analysis of Shopware's business domains, bounded contexts, and system architecture based on codebase exploration.

## Core Business Domains & Bounded Contexts

### 1. Product Management Domain (`/src/Core/Content/Product/`)

**Primary Responsibilities:**
- Product catalog management with variants and properties
- Product media, reviews, and availability tracking
- Product streams and exports for external systems
- Pricing strategies and advanced pricing rules

**Key Entities:**
- Product, ProductCollection, ProductDefinition
- ProductVariant, ProductOption, ProductProperty
- ProductMedia, ProductReview, ProductExport
- ProductStream, ProductCrossSelling

**Business Capabilities:**
- Product lifecycle management
- Variant and bundle management
- Dynamic pricing and promotions
- Product data export/import
- Search and filtering

### 2. Order Management Domain (`/src/Core/Checkout/`)

#### Cart Management (`/src/Core/Checkout/Cart/`)
**Responsibilities:**
- Shopping cart operations and persistence
- Line item management and calculations
- Promotion and discount application
- Cart validation and business rules

**Key Components:**
- Cart, CartCalculator, CartPersister
- LineItem, LineItemFactory, PriceDefinition
- CartProcessor, CartValidator
- RedisCartPersister for performance

#### Order Processing (`/src/Core/Checkout/Order/`)
**Responsibilities:**
- Order creation and state management
- Order delivery and transaction tracking
- Order documents (invoices, delivery notes)
- Order modification and cancellation

**Key Entities:**
- Order, OrderCollection, OrderDefinition
- OrderDelivery, OrderTransaction, OrderLineItem
- OrderAddress, OrderCustomer, OrderDocument

#### Customer Management (`/src/Core/Checkout/Customer/`)
**Responsibilities:**
- Customer account management
- Authentication and authorization
- Customer addresses and preferences
- Guest customer handling

**Key Components:**
- Customer, CustomerDefinition, CustomerCollection
- CustomerAddress, CustomerGroup, CustomerWishlist
- DeleteUnusedGuestCustomerService

### 3. Payment Domain (`/src/Core/Checkout/Payment/`)

**Responsibilities:**
- Payment method management
- Payment processing workflows
- Payment state machines
- Refund and recurring payment handling

**Key Components:**
- PaymentMethod, PaymentMethodDefinition
- PaymentProcessor, PaymentHandler
- PaymentTransaction, PaymentTransactionState
- Integration with external payment providers

**Default Payment Methods:**
- Cash payment method
- Invoice payment method
- Debit payment method

### 4. Shipping Domain (`/src/Core/Checkout/Shipping/`)

**Responsibilities:**
- Shipping method configuration
- Shipping cost calculations
- Delivery time management
- Shipping provider integrations

**Key Components:**
- ShippingMethod, ShippingMethodDefinition
- ShippingMethodPrice, DeliveryTime
- ShippingMethodAvailabilityRule

### 5. Content Management Domain (`/src/Core/Content/`)

#### CMS (`/src/Core/Content/Cms/`)
**Responsibilities:**
- Content page creation and management
- Block and slot-based page builder
- Dynamic content rendering
- Template and layout management

**Key Components:**
- CmsPage, CmsBlock, CmsSlot
- CmsPageDefinition, CmsBlockDefinition
- Dynamic content blocks and elements

#### Category Management (`/src/Core/Content/Category/`)
**Responsibilities:**
- Product categorization and navigation
- Category tree structure
- Category-based product assignment
- SEO-friendly category URLs

**Key Components:**
- Category, CategoryDefinition, CategoryCollection
- CategoryTree, CategoryBreadcrumb
- CategorySeoUrl, CategoryTranslation

#### Media Management (`/src/Core/Content/Media/`)
**Responsibilities:**
- File upload and storage
- Image processing and thumbnails
- Media folder organization
- External media storage integration

**Key Components:**
- Media, MediaDefinition, MediaCollection
- MediaFolder, MediaThumbnail, MediaType
- MediaService, UnusedMediaPurger

### 6. Marketing & Promotion Domain

#### Promotions (`/src/Core/Checkout/Promotion/`)
**Responsibilities:**
- Discount and promotion management
- Coupon code generation and validation
- Customer targeting and segmentation
- Promotion rule evaluation

**Key Components:**
- Promotion, PromotionDefinition
- PromotionDiscount, PromotionCode
- PromotionCartProcessor

#### Newsletter (`/src/Core/Content/Newsletter/`)
**Responsibilities:**
- Newsletter subscription management
- Email campaign integration
- Subscriber segmentation
- Double opt-in handling

### 7. SEO & URL Management (`/src/Core/Content/Seo/`)

**Responsibilities:**
- SEO-friendly URL generation
- Meta information management
- Sitemap generation
- Canonical URL handling

**Key Components:**
- SeoUrl, SeoUrlDefinition, SeoUrlGenerator
- SeoUrlTemplate, HreflangLoader
- AbstractSeoResolver, SeoUrlPersister

## System Architecture Layers

### 1. Framework Layer (`/src/Core/Framework/`)

#### Data Abstraction Layer (DAL)
**Responsibilities:**
- Custom ORM for database operations
- Entity definitions and relationships
- Query building and optimization
- Versioning and audit trails

**Key Components:**
- EntityDefinition, EntityRepository
- EntityCollection, EntityHydrator
- Criteria, Filter, Aggregation, Sorting
- VersionManager, MigrationStep

#### Event System (`/src/Core/Framework/Event/`)
**Responsibilities:**
- Business event dispatching
- Webhook integration
- Event-driven architecture
- Custom event handling

**Key Components:**
- BusinessEvents, FlowEventAware
- NestedEventDispatcher, BusinessEventCollector
- CustomerAware, OrderAware, ProductAware

#### App & Plugin System (`/src/Core/Framework/App/`, `/src/Core/Framework/Plugin/`)
**Responsibilities:**
- Third-party extension management
- App installation and lifecycle
- Plugin activation and configuration
- Marketplace integration

### 2. Administration Layer (`/src/Administration/`)

**Architecture:** Vue 3 + TypeScript + Vite

**Responsibilities:**
- Admin interface for store management
- User management with ACL
- Dashboard and analytics
- System configuration

**Key Components:**
- Vue 3 components with Composition API
- Meteor Design System components
- Admin API client integration
- Role-based access control

### 3. Storefront Layer (`/src/Storefront/`)

**Architecture:** Twig templates + Bootstrap 5 + JavaScript

**Responsibilities:**
- Customer-facing e-commerce interface
- Responsive design and themes
- Shopping cart and checkout
- Account management

**Key Features:**
- Server-side rendering with Twig
- Progressive enhancement with JavaScript
- Theme inheritance system
- Mobile-first responsive design

### 4. Search Layer (`/src/Elasticsearch/`)

**Responsibilities:**
- Product search indexing
- Search query optimization
- Faceted search and filtering
- Multi-language search support

**Key Components:**
- ElasticsearchProductDefinition
- ProductSearchBuilder, ProductSearchQueryBuilder
- CustomFieldUpdater, LanguageSubscriber

## External System Integrations

### 1. Third-Party Service Integrations

#### Email Services
- SMTP server configuration
- Authentication methods (Plain, Login, CRAM-MD5)
- SSL/TLS encryption support
- Transactional and marketing emails

#### Payment Providers
- Payment gateway APIs
- Webhook-based status updates
- Refund and recurring payment support
- PCI compliance considerations

#### Shipping Providers
- Shipping calculation APIs
- Tracking number integration
- Delivery time estimation
- Multi-carrier support

### 2. Enterprise System Integration

#### ERP/PIM Systems
- Product data synchronization
- Inventory management integration
- Order processing workflows
- Master data management

#### Analytics & Marketing
- Google Analytics integration
- Customer behavior tracking
- Marketing automation platforms
- Customer data platforms (CDP)

### 3. Infrastructure Services

#### CDN & Media Services
- External media storage
- Image optimization and resizing
- Global content delivery
- Remote thumbnail generation

#### Search Services
- Elasticsearch cluster management
- Index optimization and maintenance
- Search analytics and optimization
- Multi-language search configuration

## Data Flow Patterns

### 1. Customer Journey Flow
```
Customer → Storefront → Store API → Core Domain Logic → Database
```

### 2. Admin Operations Flow
```
Administrator → Administration → Admin API → Core Domain Logic → Database
```

### 3. External Integration Flow
```
External System → Webhook/API → Event System → Domain Logic → Business Rules
```

### 4. Business Event Flow
```
Domain Logic → Event Dispatcher → Business Events → Webhooks → External Systems
```

## Security Architecture

### Authentication & Authorization
- JWT token-based authentication
- Role-based access control (ACL)
- API key management for integrations
- Session management for web interface

### API Security
- Different scopes for Admin API vs Store API
- Rate limiting and throttling
- CORS configuration for cross-origin requests
- Input validation and sanitization

### Data Protection
- Personal data anonymization
- GDPR compliance features
- Audit trails for sensitive operations
- Secure password handling

## Key Architectural Patterns

### 1. Domain-Driven Design (DDD)
- Clear bounded contexts for business domains
- Domain services and repositories
- Aggregate roots and value objects
- Domain events for cross-boundary communication

### 2. Event-Driven Architecture
- Business events for loose coupling
- Asynchronous processing with message queues
- Webhook system for external integration
- Event sourcing for audit trails

### 3. API-First Design
- Store API for customer operations
- Admin API for management operations
- RESTful API design principles
- OpenAPI specification support

### 4. Plugin/Extension Architecture
- Dependency injection container
- Service decoration pattern
- Event subscriber system
- Configuration override system

This comprehensive domain analysis provides the foundation for understanding Shopware's business logic, system boundaries, and architectural patterns, essential for planning a rewrite or migration to another technology stack.