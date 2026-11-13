```sql
-- =============================================================================
-- Target Engine: MySQL 8.0+ / MariaDB 10.5+
-- Changes: Ingredients/Inventory removed. Simplified Menu & Current Orders tables.
-- =============================================================================

CREATE DATABASE IF NOT EXISTS `surfside_bar_and_grill`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE `surfside_bar_and_grill`;

-- -----------------------------------------------------------------------------
-- 1. AUTHENTICATION & USER MANAGEMENT
-- -----------------------------------------------------------------------------

CREATE TABLE `roles` (
    `role_id` INT AUTO_INCREMENT,
    `role_name` VARCHAR(50) NOT NULL UNIQUE,
    PRIMARY KEY (`role_id`)
) ENGINE=InnoDB;

CREATE TABLE `users` (
    `user_id` BIGINT AUTO_INCREMENT,
    `role_id` INT NOT NULL,
    `email` VARCHAR(255) NOT NULL UNIQUE,
    `password_hash` VARCHAR(255) NOT NULL,
    `first_name` VARCHAR(100) NOT NULL,
    `last_name` VARCHAR(100) NOT NULL,
    `phone_number` VARCHAR(20) NOT NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`user_id`),
    CONSTRAINT `fk_users_roles` FOREIGN KEY (`role_id`) 
        REFERENCES `roles` (`role_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `customer_profiles` (
    `customer_id` BIGINT PRIMARY KEY,
    `loyalty_points` INT NOT NULL DEFAULT 0,
    `saved_address` TEXT DEFAULT NULL,
    CONSTRAINT `fk_customer_users` FOREIGN KEY (`customer_id`) 
        REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `employee_profiles` (
    `employee_id` BIGINT PRIMARY KEY,
    `employee_code` VARCHAR(20) NOT NULL UNIQUE,
    `override_pin_hash` VARCHAR(255) DEFAULT NULL,
    CONSTRAINT `fk_employee_users` FOREIGN KEY (`employee_id`) 
        REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 2. MENU DATABASE (MANAGERS CAN EDIT ITEMS & TOGGLE AVAILABILITY)
-- -----------------------------------------------------------------------------

CREATE TABLE `menu_categories` (
    `category_id` INT AUTO_INCREMENT,
    `category_name` VARCHAR(100) NOT NULL UNIQUE,
    `display_order` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`category_id`)
) ENGINE=InnoDB;

CREATE TABLE `menu_items` (
    `item_id` BIGINT AUTO_INCREMENT,
    `category_id` INT NOT NULL,
    `item_name` VARCHAR(150) NOT NULL,
    `description` TEXT DEFAULT NULL,
    `price` DECIMAL(10, 2) NOT NULL,
    `is_available` BOOLEAN NOT NULL DEFAULT TRUE, -- Managers edit this directly
    `image_url` VARCHAR(255) DEFAULT NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`item_id`),
    CONSTRAINT `fk_menu_items_category` FOREIGN KEY (`category_id`) 
        REFERENCES `menu_categories` (`category_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 3. CURRENT ORDERS DATABASE (VISIBLE TO CUSTOMERS & EMPLOYEES)
-- -----------------------------------------------------------------------------

CREATE TABLE `orders` (
    `order_id` BIGINT AUTO_INCREMENT,
    `customer_id` BIGINT DEFAULT NULL, -- Allows customers to view their own order history
    `employee_id` BIGINT DEFAULT NULL, -- Set if placed in-person/phone by an employee
    `order_source` ENUM('ONLINE', 'PHONE', 'IN_PERSON') NOT NULL,
    `order_status` ENUM('PREPARATION', 'IN_OVEN', 'READY_FOR_PICKUP', 'COMPLETED', 'CANCELLED') NOT NULL DEFAULT 'PREPARATION',
    `subtotal` DECIMAL(10, 2) NOT NULL,
    `tax_amount` DECIMAL(10, 2) NOT NULL,
    `total_amount` DECIMAL(10, 2) NOT NULL,
    `payment_status` ENUM('PENDING', 'PAID', 'REFUNDED') NOT NULL DEFAULT 'PENDING',
    `payment_token` VARCHAR(255) DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`order_id`),
    CONSTRAINT `fk_orders_customer` FOREIGN KEY (`customer_id`) 
        REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT `fk_orders_employee` FOREIGN KEY (`employee_id`) 
        REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `order_items` (
    `order_item_id` BIGINT AUTO_INCREMENT,
    `order_id` BIGINT NOT NULL,
    `menu_item_id` BIGINT NOT NULL,
    `quantity` INT NOT NULL CHECK (`quantity` > 0),
    `unit_price` DECIMAL(10, 2) NOT NULL,
    `special_notes` TEXT DEFAULT NULL,
    PRIMARY KEY (`order_item_id`),
    CONSTRAINT `fk_order_items_order` FOREIGN KEY (`order_id`) 
        REFERENCES `orders` (`order_id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_order_items_menu` FOREIGN KEY (`menu_item_id`) 
        REFERENCES `menu_items` (`item_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `order_audit_logs` (
    `log_id` BIGINT AUTO_INCREMENT,
    `order_id` BIGINT NOT NULL,
    `action_type` VARCHAR(50) NOT NULL,
    `performed_by` BIGINT NOT NULL,
    `authorized_by` BIGINT DEFAULT NULL,
    `notes` TEXT DEFAULT NULL,
    `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`log_id`),
    CONSTRAINT `fk_audit_order` FOREIGN KEY (`order_id`) 
        REFERENCES `orders` (`order_id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_audit_performer` FOREIGN KEY (`performed_by`) 
        REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_audit_authorizer` FOREIGN KEY (`authorized_by`) 
        REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 4. DAILY DEALS & ABOUT PAGE
-- -----------------------------------------------------------------------------

CREATE TABLE `daily_deals` (
    `deal_id` BIGINT AUTO_INCREMENT,
    `title` VARCHAR(150) NOT NULL,
    `description` TEXT NOT NULL,
    `discount_percentage` DECIMAL(5, 2) DEFAULT NULL,
    `event_date` DATE NOT NULL,
    `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
    `created_by` BIGINT NOT NULL,
    PRIMARY KEY (`deal_id`),
    CONSTRAINT `fk_deals_user` FOREIGN KEY (`created_by`) 
        REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `about_content` (
    `content_id` INT AUTO_INCREMENT,
    `section_key` VARCHAR(50) NOT NULL UNIQUE,
    `title` VARCHAR(200) NOT NULL,
    `body_content` TEXT NOT NULL,
    `updated_by` BIGINT NOT NULL,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`content_id`),
    CONSTRAINT `fk_about_user` FOREIGN KEY (`updated_by`) 
        REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- -----------------------------------------------------------------------------
-- 5. DEFAULT SEED DATA
-- -----------------------------------------------------------------------------

INSERT INTO `roles` (`role_id`, `role_name`) VALUES 
(1, 'Customer'),
(2, 'Employee'),
(3, 'Manager'),
(4, 'Admin');

```
