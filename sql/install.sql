CREATE TABLE IF NOT EXISTS `dj_donator_coins` (
    `identifier` VARCHAR(64) NOT NULL,
    `coins` INT NOT NULL DEFAULT 0,
    `lifetime_spent` INT NOT NULL DEFAULT 0,
    `lifetime_granted` INT NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `dj_donator_owned` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(64) NOT NULL,
    `item_id` VARCHAR(64) NOT NULL,
    `category` VARCHAR(32) NOT NULL,
    `tier` VARCHAR(16) DEFAULT NULL,
    `label` VARCHAR(128) NOT NULL,
    `data` LONGTEXT,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `identifier_item` (`identifier`, `item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `dj_donator_purchases` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(64) NOT NULL,
    `player_name` VARCHAR(64) DEFAULT NULL,
    `item_id` VARCHAR(64) NOT NULL,
    `label` VARCHAR(128) NOT NULL,
    `category` VARCHAR(32) NOT NULL,
    `tier` VARCHAR(16) DEFAULT NULL,
    `price` INT NOT NULL,
    `quantity` INT NOT NULL DEFAULT 1,
    `gifted_to` VARCHAR(64) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `identifier_created` (`identifier`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `dj_donator_logs` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `actor_identifier` VARCHAR(64) NOT NULL,
    `actor_name` VARCHAR(64) DEFAULT NULL,
    `target_identifier` VARCHAR(64) DEFAULT NULL,
    `target_name` VARCHAR(64) DEFAULT NULL,
    `action` VARCHAR(64) NOT NULL,
    `details` LONGTEXT,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `created_at` (`created_at`),
    KEY `action` (`action`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `dj_donator_codes` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `code` VARCHAR(32) NOT NULL,
    `coins` INT NOT NULL DEFAULT 0,
    `item_id` VARCHAR(64) DEFAULT NULL,
    `max_uses` INT NOT NULL DEFAULT 1,
    `uses` INT NOT NULL DEFAULT 0,
    `expires_at` TIMESTAMP NULL DEFAULT NULL,
    `created_by` VARCHAR(64) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `dj_donator_code_redemptions` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `code_id` INT NOT NULL,
    `identifier` VARCHAR(64) NOT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `code_player` (`code_id`, `identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
