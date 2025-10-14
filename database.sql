-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 13, 2025 at 09:41 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12
CREATE DATABASE IF NOT EXISTS website_monitor CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE website_monitor;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `website_monitor`
--

-- --------------------------------------------------------

--
-- Table structure for table `change_history`
--

CREATE TABLE `change_history` (
  `id` int(11) NOT NULL,
  `site_id` int(11) NOT NULL,
  `previous_check_id` int(11) DEFAULT NULL,
  `current_check_id` int(11) NOT NULL,
  `change_type` varchar(50) NOT NULL,
  `change_description` text DEFAULT NULL,
  `old_value` text DEFAULT NULL,
  `new_value` text DEFAULT NULL,
  `severity` enum('low','medium','high','critical') DEFAULT 'medium',
  `detected_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `monitored_sites`
--

CREATE TABLE `monitored_sites` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `url` varchar(500) NOT NULL,
  `name` varchar(100) NOT NULL,
  `check_interval_hours` int(11) DEFAULT 24,
  `keywords` text DEFAULT NULL,
  `last_check` timestamp NULL DEFAULT NULL,
  `last_content_hash` varchar(255) DEFAULT NULL,
  `last_status_code` int(11) DEFAULT NULL,
  `last_response_time_ms` int(11) DEFAULT NULL,
  `last_scraping_method` varchar(50) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `is_global_notification` tinyint(1) DEFAULT 0,
  `scraping_method` enum('api','dom_parser') DEFAULT 'api',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `monitored_sites`
--

-- Default Kao Kirei sites for global notifications
INSERT INTO `monitored_sites` (`id`, `user_id`, `url`, `name`, `check_interval_hours`, `keywords`, `last_check`, `last_content_hash`, `last_status_code`, `last_response_time_ms`, `last_scraping_method`, `is_active`, `is_global_notification`, `scraping_method`, `created_at`, `updated_at`) VALUES
(1, 0, 'https://www.kao-kirei.com/ja/expire-item/khg/?tw=khg', '花王 家庭用品の製造終了品一覧', 24, '製造終了品,家庭用品,花王', NULL, NULL, NULL, NULL, 'dom_parser', 1, 1, 'dom_parser', NOW(), NOW()),
(2, 0, 'https://www.kao-kirei.com/ja/expire-item/kbb/?tw=kbb', '花王・カネボウ化粧品 製造終了品一覧', 24, '製造終了品,化粧品,花王,カネボウ', NULL, NULL, NULL, NULL, 'dom_parser', 1, 1, 'dom_parser', NOW(), NOW());

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `site_id` int(11) NOT NULL,
  `type` enum('email','line') NOT NULL,
  `message` text NOT NULL,
  `sent_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` enum('pending','sent','failed') DEFAULT 'pending',
  `is_global` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Sample global notifications for Kao Kirei sites
INSERT INTO `notifications` (`id`, `user_id`, `site_id`, `type`, `message`, `sent_at`, `status`, `is_global`) VALUES
(1, NULL, 1, 'email', '花王 家庭用品の製造終了品一覧に変更が検出されました。新しい商品が追加されたか、既存の商品が削除された可能性があります。', NOW(), 'pending', 1),
(2, NULL, 2, 'line', '花王・カネボウ化粧品 製造終了品一覧に変更が検出されました。新しい商品が追加されたか、既存の商品が削除された可能性があります。', NOW(), 'pending', 1);

-- --------------------------------------------------------

--
-- Table structure for table `product_data`
--

CREATE TABLE `product_data` (
  `id` int(11) NOT NULL,
  `site_id` int(11) NOT NULL,
  `site_check_id` int(11) NOT NULL,
  `product_name` varchar(500) NOT NULL,
  `product_category` varchar(200) DEFAULT NULL,
  `product_status` varchar(100) DEFAULT NULL,
  `product_regulation` varchar(100) DEFAULT NULL,
  `product_link` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scraped_content`
--

CREATE TABLE `scraped_content` (
  `id` int(11) NOT NULL,
  `site_check_id` int(11) NOT NULL,
  `content_type` enum('full_html','text_content','metadata') NOT NULL,
  `content_data` longtext DEFAULT NULL,
  `content_size` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `site_checks`
--

CREATE TABLE `site_checks` (
  `id` int(11) NOT NULL,
  `site_id` int(11) NOT NULL,
  `content_hash` varchar(255) DEFAULT NULL,
  `text_content` longtext DEFAULT NULL,
  `content_length` int(11) DEFAULT NULL,
  `status_code` int(11) DEFAULT NULL,
  `response_time_ms` int(11) DEFAULT NULL,
  `scraping_method` varchar(50) DEFAULT NULL,
  `changes_detected` tinyint(1) DEFAULT 0,
  `reason` text DEFAULT NULL,
  `change_type` varchar(50) DEFAULT NULL,
  `change_reason` text DEFAULT NULL,
  `keywords_found` tinyint(1) DEFAULT 0,
  `keywords_list` text DEFAULT NULL,
  `error_message` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `site_checks`
--

-- Sample data will be inserted after users are created

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `line_user_id` varchar(100) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `is_admin` tinyint(1) DEFAULT 0,
  `is_blocked` tinyint(1) DEFAULT 0,
  `blocked_at` timestamp NULL DEFAULT NULL,
  `blocked_by` int(11) DEFAULT NULL,
  `block_reason` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

-- System user for global notifications
INSERT INTO `users` (`id`, `username`, `email`, `password_hash`, `line_user_id`, `is_active`, `is_admin`, `is_blocked`, `blocked_at`, `blocked_by`, `block_reason`, `created_at`, `updated_at`) VALUES
(0, 'system_global', 'system@global.notifications', '', NULL, 1, 1, 0, NULL, NULL, NULL, NOW(), NOW());

-- --------------------------------------------------------

--
-- Table structure for table `user_notifications`
--

CREATE TABLE `user_notifications` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `email_enabled` tinyint(1) DEFAULT 1,
  `line_enabled` tinyint(1) DEFAULT 0,
  `line_user_id` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `change_history`
--
ALTER TABLE `change_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `previous_check_id` (`previous_check_id`),
  ADD KEY `current_check_id` (`current_check_id`),
  ADD KEY `idx_change_history_site_id` (`site_id`),
  ADD KEY `idx_change_history_detected_at` (`detected_at`);

--
-- Indexes for table `monitored_sites`
--
ALTER TABLE `monitored_sites`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_monitored_sites_user_id` (`user_id`),
  ADD KEY `idx_monitored_sites_last_check` (`last_check`),
  ADD KEY `idx_monitored_sites_user_active` (`user_id`, `is_active`),
  ADD KEY `idx_monitored_sites_user_created` (`user_id`, `created_at`),
  ADD KEY `idx_monitored_sites_global_notification` (`is_global_notification`),
  ADD KEY `idx_monitored_sites_scraping_method` (`scraping_method`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `site_id` (`site_id`),
  ADD KEY `idx_notifications_user_id` (`user_id`),
  ADD KEY `idx_notifications_sent_at` (`sent_at`),
  ADD KEY `idx_notifications_is_global` (`is_global`);

--
-- Indexes for table `product_data`
--
ALTER TABLE `product_data`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_product_data_site_id` (`site_id`),
  ADD KEY `idx_product_data_site_check_id` (`site_check_id`),
  ADD KEY `idx_product_data_product_name` (`product_name`(100)),
  ADD KEY `idx_product_data_created_at` (`created_at`);

--
-- Indexes for table `scraped_content`
--
ALTER TABLE `scraped_content`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_scraped_content_site_check_id` (`site_check_id`),
  ADD KEY `idx_scraped_content_content_type` (`content_type`);

--
-- Indexes for table `site_checks`
--
ALTER TABLE `site_checks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_site_checks_site_id` (`site_id`),
  ADD KEY `idx_site_checks_created_at` (`created_at`),
  ADD KEY `idx_site_checks_changes_detected` (`changes_detected`),
  ADD KEY `idx_site_checks_text_content` (`text_content`(100));

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_users_is_blocked` (`is_blocked`),
  ADD KEY `idx_users_blocked_at` (`blocked_at`),
  ADD KEY `idx_users_blocked_by` (`blocked_by`);

--
-- Indexes for table `user_notifications`
--
ALTER TABLE `user_notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `change_history`
--
ALTER TABLE `change_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `monitored_sites`
--
ALTER TABLE `monitored_sites`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `product_data`
--
ALTER TABLE `product_data`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scraped_content`
--
ALTER TABLE `scraped_content`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `site_checks`
--
ALTER TABLE `site_checks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_notifications`
--
ALTER TABLE `user_notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `change_history`
--
ALTER TABLE `change_history`
  ADD CONSTRAINT `change_history_ibfk_1` FOREIGN KEY (`site_id`) REFERENCES `monitored_sites` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `change_history_ibfk_2` FOREIGN KEY (`previous_check_id`) REFERENCES `site_checks` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `change_history_ibfk_3` FOREIGN KEY (`current_check_id`) REFERENCES `site_checks` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `monitored_sites`
--




























ALTER TABLE `monitored_sites`
  ADD CONSTRAINT `monitored_sites_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `notifications_ibfk_2` FOREIGN KEY (`site_id`) REFERENCES `monitored_sites` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `product_data`
--
ALTER TABLE `product_data`
  ADD CONSTRAINT `product_data_ibfk_1` FOREIGN KEY (`site_id`) REFERENCES `monitored_sites` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `product_data_ibfk_2` FOREIGN KEY (`site_check_id`) REFERENCES `site_checks` (`id`) ON DELETE CASCADE;

-- --
-- -- Constraints for table `scraped_content`
-- --
-- ALTER TABLE `scraped_content`
--   ADD CONSTRAINT `scraped_content_ibfk_1` FOREIGN KEY (`site_check_id`) REFERENCES `site_checks` (`id`) ON DELETE CASCADE;

-- --
-- -- Constraints for table `site_checks`
-- --
-- ALTER TABLE `site_checks`
--   ADD CONSTRAINT `site_checks_ibfk_1` FOREIGN KEY (`site_id`) REFERENCES `monitored_sites` (`id`) ON DELETE CASCADE;

-- --
-- -- Constraints for table `user_notifications`
-- --
-- ALTER TABLE `user_notifications`
--   ADD CONSTRAINT `user_notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

-- --
-- -- Constraints for table `users` (blocked_by)
-- --
ALTER TABLE `users`
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`blocked_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

-- COMMIT;

-- /*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
-- /*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
-- /*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
