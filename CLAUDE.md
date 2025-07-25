# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Setup & Installation
```bash
composer setup              # Complete setup (dependencies, DB, build assets)
composer reset              # Reset and reinstall (faster if no deps changed)
composer init:db            # Initialize database only
composer init:js            # Initialize JavaScript dependencies
composer init:testdb        # Initialize test database
```

### Testing
```bash
composer phpunit            # Run all PHPUnit tests
composer admin:unit         # Run Administration unit tests (Jest)
composer admin:unit:watch   # Watch mode for Admin tests
composer storefront:unit    # Run Storefront unit tests (Jest)
composer storefront:unit:watch  # Watch mode for Storefront tests
```

### Building & Development
```bash
composer build:js           # Build both Administration and Storefront
composer build:js:admin     # Build Administration only
composer build:js:storefront # Build Storefront only
composer watch:admin        # Start Admin development server with HMR
composer watch:storefront   # Start Storefront development server with HMR
```

### Code Quality
```bash
composer lint               # Run all linting (ESLint + Stylelint + ECS + changelog + snippets)
composer ecs                # PHP CS Fixer check only
composer ecs-fix            # PHP CS Fixer fix issues
composer phpstan            # PHPStan static analysis
composer eslint:admin       # ESLint for Administration
composer eslint:admin:fix   # Fix ESLint issues in Administration
composer stylelint          # Stylelint for SCSS files
```

### Running Single Tests
```bash
# PHPUnit
phpunit --testsuite=unit
phpunit --testsuite=integration
phpunit tests/unit/Core/Content/Product/ProductTest.php

# Jest (Administration)
cd src/Administration/Resources/app/administration && npm run unit -- SpecificTest.spec.js

# Jest (Storefront)
cd src/Storefront/Resources/app/storefront && npm run unit -- SpecificTest.spec.js
```

## Architecture Overview

Shopware is a headless e-commerce platform built on **Symfony 7** with **Vue.js 3** administration interface.

### Core Components
- **Core**: Symfony-based API and business logic (`src/Core/`)
- **Administration**: Vue 3 + TypeScript admin interface using Vite (`src/Administration/`)
- **Storefront**: Customer-facing interface using Webpack + Bootstrap 5 (`src/Storefront/`)
- **Elasticsearch**: Search and indexing functionality (`src/Elasticsearch/`)

### Key Architecture Patterns
- **Data Abstraction Layer (DAL)**: Custom ORM for entities and repositories
- **Business Events**: Event-driven architecture with FlowBuilder support
- **Plugin System**: Extensions via Symfony bundles in `custom/plugins/`
- **App System**: Lightweight extensions via manifest files
- **API-First**: Store API for headless commerce, Admin API for management

### Main Business Domains
- **Checkout**: Cart, Order, Payment, Shipping (`src/Core/Checkout/`)
- **Content**: CMS, Categories, Products, Media (`src/Core/Content/`)
- **System**: Countries, Currencies, Languages, Users (`src/Core/System/`)
- **Framework**: Core infrastructure, DAL, Rules, Events (`src/Core/Framework/`)

### Frontend Architecture
- **Administration**: Vue 3 Composition API + Vite, TypeScript, Meteor Design System
- **Storefront**: Traditional server-rendered Twig templates with JavaScript enhancements
- **Theming**: SCSS-based theme system with inheritance support

### Database & Entities
- MySQL/MariaDB with custom DAL abstraction
- Entities use `EntityDefinition` classes with field definitions
- Support for versioning, translations, and custom fields
- Elasticsearch integration for search and aggregations

## Development Workflow

### Daily Development
1. Use `composer watch:admin` or `composer watch:storefront` for HMR development
2. Run `composer lint` before committing changes
3. Run relevant tests: `composer admin:unit`, `composer storefront:unit`, `composer phpunit`

### Code Conventions
- **PHP**: PSR-12 with custom rules via PHP CS Fixer
- **JavaScript/TypeScript**: ESLint with Vue and TypeScript rules
- **SCSS**: Stylelint with custom Shopware rules
- **Twig**: Ludtwig for template linting

### Testing Strategy
- **Unit Tests**: Individual class/component testing
- **Integration Tests**: Database and service integration
- **Acceptance Tests**: End-to-end testing with Playwright (`tests/acceptance/`)
- **Migration Tests**: Database migration validation

### Key Files
- `composer.json`: All development scripts and dependencies
- `src/Administration/Resources/app/administration/package.json`: Admin build configuration
- `src/Storefront/Resources/app/storefront/package.json`: Storefront build configuration
- `phpunit.xml.dist`: PHPUnit configuration
- `phpstan.neon.dist`: Static analysis configuration

### Development URLs
- Main Application: `http://localhost:8000`
- Admin Panel: `http://localhost:8000/admin`
- Administration HMR: `http://localhost:5773`
- Storefront HMR: `http://localhost:9998`

### Extensions
- **Plugins**: Symfony bundles in `custom/plugins/` with PHP classes
- **Apps**: Manifest-based extensions with webhooks and custom endpoints
- **Themes**: SCSS-based themes extending the base Storefront theme

## Important Notes

- Always run `composer ecs-fix` and `composer lint` before committing
- Use `composer phpstan` for static analysis
- The main branch is `trunk`, not `master`
- PHP 8.2+ required, Node.js 20+ for Administration
- Database migrations are in `src/*/Migration/` directories
- Custom entities use the AttributeEntity system
- Business events can trigger Flow actions for automation