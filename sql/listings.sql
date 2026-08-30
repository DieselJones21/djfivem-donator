-- Run this if you already imported install.sql before listings existed.
-- New installs can skip this file (it is included in install.sql).

CREATE TABLE IF NOT EXISTS `dj_305donator_listings` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `item_id` VARCHAR(64) NOT NULL,
    `category` VARCHAR(32) NOT NULL,
    `tier` VARCHAR(16) DEFAULT NULL,
    `label` VARCHAR(128) NOT NULL,
    `description` TEXT,
    `price` INT NOT NULL DEFAULT 0,
    `image` VARCHAR(512) DEFAULT NULL,
    `image_key` VARCHAR(64) DEFAULT NULL,
    `item_name` VARCHAR(64) DEFAULT NULL,
    `weapon` VARCHAR(64) DEFAULT NULL,
    `model` VARCHAR(64) DEFAULT NULL,
    `pet_model` VARCHAR(64) DEFAULT NULL,
    `ammo` INT DEFAULT NULL,
    `item_count` INT NOT NULL DEFAULT 1,
    `extras` LONGTEXT,
    `unique_item` TINYINT(1) NOT NULL DEFAULT 0,
    `stock` INT DEFAULT NULL,
    `limited_from` VARCHAR(32) DEFAULT NULL,
    `limited_until` VARCHAR(32) DEFAULT NULL,
    `garage_id` VARCHAR(64) DEFAULT NULL,
    `garage_type` VARCHAR(16) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `item_id` (`item_id`),
    KEY `category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
