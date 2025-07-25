# Shopware C4 Container Diagram (PlantUML)

This document contains the C4 Container diagram for the Shopware e-commerce platform using PlantUML notation, showing the internal architecture, containers, and their interactions.

## PlantUML Container Diagram

```plantuml
@startuml Shopware-Container-Diagram
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml

LAYOUT_WITH_LEGEND()

title Container diagram for Shopware E-Commerce Platform

' External Users/Personas
Person(customer, "Customer", "End user shopping online")
Person(guest, "Guest User", "Anonymous visitor")
Person(merchant, "Store Manager", "Manages store operations")
Person(admin, "System Administrator", "System configuration")
Person(editor, "Content Editor", "Content management")
Person(support, "Customer Service", "Customer support")

' System Boundary
System_Boundary(shopware, "Shopware E-Commerce Platform") {
    
    ' Frontend Containers
    Container(admin_app, "Administration App", "Vue.js 3, TypeScript, Vite", "Admin interface for store management with role-based access control, dashboard, and business operations")
    
    Container(storefront_app, "Storefront App", "PHP/Twig, Bootstrap 5, JavaScript", "Server-rendered customer-facing e-commerce interface with shopping cart, checkout, and account management")
    
    ' Backend Containers
    Container(core_api, "Core Backend API", "Symfony 7, PHP 8.2+", "Business logic engine with Admin API (/api/*) and Store API (/store-api/*) providing all e-commerce functionality")
    
    ' Data Storage Containers
    ContainerDb(database, "Primary Database", "MySQL/MariaDB", "Stores all business data: products, orders, customers, content, configuration with multi-language support")
    
    Container(search_engine, "Search Engine", "Elasticsearch/OpenSearch", "Product search indexing, full-text search, faceted filtering, and search analytics")
    
    Container(cache_system, "Cache System", "Filesystem/Redis", "Performance optimization with object cache, HTTP cache, and tag-based invalidation")
    
    Container(file_storage, "File Storage", "Filesystem/S3", "Media files, product images, documents, theme assets, and user uploads")
    
    ' Background Processing
    Container(message_queue, "Message Queue", "Symfony Messenger", "Asynchronous processing for search indexing, email sending, and background tasks")
}

' External Systems
System_Ext(payment_gateway, "Payment Providers", "Payment processing services")
System_Ext(shipping_provider, "Shipping Providers", "Logistics and delivery services")
System_Ext(email_service, "Email Service", "SMTP servers")
System_Ext(cdn, "CDN/Media Services", "Content delivery network")
System_Ext(erp_system, "ERP/PIM Systems", "Enterprise systems")
System_Ext(analytics, "Analytics Services", "Web analytics")
System_Ext(external_systems, "External Systems", "Third-party integrations")

' User Interactions
Rel(customer, storefront_app, "Browses, shops, manages account", "HTTPS")
Rel(guest, storefront_app, "Browses, makes purchases", "HTTPS")

Rel(merchant, admin_app, "Manages products, orders, customers", "HTTPS")
Rel(admin, admin_app, "System configuration, monitoring", "HTTPS")
Rel(editor, admin_app, "Content and media management", "HTTPS")
Rel(support, admin_app, "Customer service operations", "HTTPS")

' Frontend to Backend Communication
Rel(admin_app, core_api, "Management operations", "HTTPS/Admin API (JSON)")
Rel(storefront_app, core_api, "Business operations", "HTTPS/Store API (JSON)")

' Backend to Data Storage
Rel(core_api, database, "CRUD operations", "MySQL Protocol/DAL")
Rel(core_api, search_engine, "Index products, search queries", "HTTP/REST API")
Rel(core_api, cache_system, "Cache operations", "Filesystem/Redis Protocol")
Rel(core_api, file_storage, "File operations", "Filesystem/S3 API")

' Async Processing
Rel(core_api, message_queue, "Queue messages", "Internal")
Rel(message_queue, search_engine, "Async indexing", "HTTP/REST API")
Rel(message_queue, email_service, "Send emails", "SMTP")

' Search Engine Data
Rel(search_engine, database, "Index data synchronization", "MySQL Protocol")

' External Integrations
Rel(core_api, payment_gateway, "Payment processing", "HTTPS/REST API")
Rel(payment_gateway, core_api, "Payment status updates", "HTTPS/Webhooks")

Rel(core_api, shipping_provider, "Shipping calculations", "HTTPS/REST API")
Rel(shipping_provider, core_api, "Delivery updates", "HTTPS/Webhooks")

Rel(core_api, email_service, "Transactional emails", "SMTP")
Rel(core_api, cdn, "Media delivery", "HTTPS/REST API")

Rel(erp_system, core_api, "Data synchronization", "HTTPS/REST API")
Rel(core_api, external_systems, "Business events", "HTTPS/Webhooks")
Rel(core_api, analytics, "Tracking data", "HTTPS/Analytics API")

' Layout positioning
Lay_D(customer, storefront_app)
Lay_D(merchant, admin_app)
Lay_D(admin_app, core_api)
Lay_D(storefront_app, core_api)
Lay_D(core_api, database)
Lay_R(database, search_engine)
Lay_R(search_engine, cache_system)
Lay_R(cache_system, file_storage)
Lay_U(message_queue, core_api)

@enduml
```

## Container Architecture Description

### Frontend Application Containers

#### **Administration App**
- **Technology Stack**: Vue.js 3, TypeScript, Vite
- **Purpose**: Admin interface for comprehensive store management
- **Key Features**:
  - Role-based access control (ACL) with granular permissions
  - Real-time dashboard with business metrics
  - Product catalog management with variants and properties
  - Order processing and customer service tools
  - Content management system with page builder
  - Plugin and theme management interface
- **Development**: Hot Module Replacement (HMR) on port 5173
- **Communication**: Consumes Admin API exclusively

#### **Storefront App**
- **Technology Stack**: PHP/Twig templating, Bootstrap 5, JavaScript
- **Purpose**: Customer-facing e-commerce interface
- **Key Features**:
  - Server-side rendering for SEO optimization
  - Responsive mobile-first design
  - Shopping cart and checkout flow
  - Customer account management
  - Product browsing and search
  - Theme system with inheritance
- **Development**: Webpack dev server with hot reload on port 9998
- **Communication**: Direct server rendering + Store API for dynamic content

### Backend Core Container

#### **Core Backend API**
- **Technology Stack**: Symfony 7, PHP 8.2+
- **Purpose**: Central business logic and API gateway
- **API Endpoints**:
  - **Admin API** (`/api/*`): Full CRUD operations with authentication
  - **Store API** (`/store-api/*`): Customer-facing operations
- **Business Domains**:
  - **Checkout**: Cart, Orders, Payments, Shipping
  - **Content**: Products, Categories, CMS, Media
  - **System**: Users, Configuration, Internationalization
  - **Framework**: DAL, Events, Rules, Extensions
- **Architecture Patterns**:
  - Data Abstraction Layer (DAL) for database operations
  - Event-driven architecture with business events
  - Plugin/App system for extensibility
  - Custom rule engine for business logic

### Data Storage Containers

#### **Primary Database**
- **Technology**: MySQL/MariaDB
- **Purpose**: Transactional data storage with ACID compliance
- **Features**:
  - Multi-language support with translation tables
  - Entity versioning for content management
  - Custom fields for runtime extensibility
  - Migration system for schema evolution
- **Access Pattern**: Custom DAL with repository pattern

#### **Search Engine**
- **Technology**: Elasticsearch/OpenSearch
- **Purpose**: High-performance search and analytics
- **Capabilities**:
  - Full-text product search with relevance scoring
  - Faceted search and filtering
  - Multi-language search with analyzers
  - Admin search for backend operations
  - Search analytics and optimization
- **Indexing**: Asynchronous via message queue

#### **Cache System**
- **Technology**: Filesystem-based (configurable to Redis)
- **Purpose**: Performance optimization across all layers
- **Cache Types**:
  - **Object Cache**: Entity and service caching
  - **HTTP Cache**: Full-page and API response caching
  - **Tag-based Cache**: Selective invalidation
  - **Rate Limiter Cache**: API protection
- **TTL**: Configurable with 48-hour default

#### **File Storage**
- **Technology**: Filesystem (S3-compatible)
- **Purpose**: Digital asset management
- **Contents**:
  - Product media and images
  - Generated thumbnails in multiple sizes
  - Theme assets and compiled stylesheets
  - Document templates and generated PDFs
  - Plugin assets and uploads

### Infrastructure Containers

#### **Message Queue**
- **Technology**: Symfony Messenger with Doctrine transport
- **Purpose**: Asynchronous processing and system decoupling
- **Queue Types**:
  - **Async**: Standard background processing
  - **Low Priority**: Non-critical tasks
  - **Failed**: Error handling and retry
- **Use Cases**:
  - Elasticsearch indexing operations
  - Email sending and notifications
  - Import/export data processing
  - Cache warming and maintenance

## Communication Patterns

### **Inter-Container Communication**

#### **Frontend → Backend**
- **Protocol**: HTTP/HTTPS with JSON payloads
- **Authentication**: JWT tokens (Admin), Session tokens (Store)
- **API Design**: RESTful with OpenAPI specifications
- **Rate Limiting**: Per-user and per-IP protection

#### **Backend → Database**
- **Protocol**: MySQL protocol with connection pooling
- **Abstraction**: Custom DAL with entity definitions
- **Transaction Management**: ACID compliance with rollback support
- **Query Optimization**: Index usage and query caching

#### **Async Processing**
- **Message Transport**: Database-backed message queue
- **Reliability**: Message acknowledgment and retry logic
- **Scalability**: Configurable worker processes
- **Monitoring**: Message queue statistics and health checks

### **External Integration Patterns**

#### **API-Based Integration**
- **Outbound**: REST API calls to payment, shipping, analytics services
- **Inbound**: Webhook endpoints for status updates and notifications
- **Security**: HMAC signature verification for webhooks
- **Reliability**: Exponential backoff retry logic

#### **Event-Driven Integration**
- **Business Events**: Order placed, customer registered, product updated
- **Webhook Delivery**: Reliable delivery to external systems
- **Event Sourcing**: Audit trail for business-critical events
- **Custom Integrations**: Plugin/App system for specialized needs

## Technology Characteristics

### **Scalability**
- **Horizontal Scaling**: Stateless application containers
- **Database Scaling**: Read replicas and connection pooling
- **Cache Scaling**: Distributed caching with Redis cluster
- **Search Scaling**: Elasticsearch cluster with sharding

### **Performance**
- **Frontend Optimization**: Server-side rendering + progressive enhancement
- **API Performance**: Efficient DAL queries with eager loading
- **Caching Strategy**: Multi-level caching with tag-based invalidation
- **Asset Optimization**: CDN integration and image processing

### **Security**
- **Authentication**: Multi-factor authentication for admin users
- **Authorization**: Role-based access control with granular permissions
- **Data Protection**: Input validation, output encoding, SQL injection prevention
- **Infrastructure Security**: HTTPS enforcement, security headers, CORS configuration

This container diagram provides a comprehensive view of Shopware's internal architecture, showing how the different applications, services, and data stores work together to deliver a complete e-commerce platform.