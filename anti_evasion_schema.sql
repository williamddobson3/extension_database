-- Anti-Evasion System Database Schema
-- Prevents blocked users from creating new accounts with different emails/names

-- --------------------------------------------------------

--
-- Table structure for table `evasion_signals`
-- Stores all signals collected during registration for analysis
--

CREATE TABLE `evasion_signals` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `session_id` varchar(255) NOT NULL,
  `normalized_email` varchar(255) NOT NULL,
  `email_domain` varchar(100) NOT NULL,
  `normalized_name` varchar(255) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `ip_subnet` varchar(18) NOT NULL,
  `asn` varchar(20) DEFAULT NULL,
  `fp_hash` varchar(64) NOT NULL,
  `user_agent` text DEFAULT NULL,
  `screen_resolution` varchar(20) DEFAULT NULL,
  `timezone` varchar(50) DEFAULT NULL,
  `language` varchar(10) DEFAULT NULL,
  `mx_record_exists` tinyint(1) DEFAULT NULL,
  `spf_record_exists` tinyint(1) DEFAULT NULL,
  `disposable_email` tinyint(1) DEFAULT 0,
  `captcha_score` decimal(3,2) DEFAULT NULL,
  `proof_of_work_token` varchar(64) DEFAULT NULL,
  `form_completion_time` int(11) DEFAULT NULL,
  `risk_score` int(11) DEFAULT 0,
  `signal_details` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `banned_signals`
-- Stores banned signals (emails, fingerprints, IPs, etc.)
--

CREATE TABLE `banned_signals` (
  `id` int(11) NOT NULL,
  `signal_type` enum('email','fp_hash','ip','subnet','asn','name') NOT NULL,
  `signal_value` varchar(500) NOT NULL,
  `banned_by` int(11) NOT NULL,
  `reason` text DEFAULT NULL,
  `severity` enum('low','medium','high','critical') DEFAULT 'medium',
  `auto_detected` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expires_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `evasion_attempts`
-- Records all evasion attempts and their outcomes
--

CREATE TABLE `evasion_attempts` (
  `id` int(11) NOT NULL,
  `session_id` varchar(255) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `attempt_type` enum('registration','login','password_reset') NOT NULL,
  `risk_score` int(11) NOT NULL,
  `action_taken` enum('allowed','challenged','blocked','review') NOT NULL,
  `challenge_type` varchar(50) DEFAULT NULL,
  `challenge_completed` tinyint(1) DEFAULT 0,
  `admin_reviewed` tinyint(1) DEFAULT 0,
  `admin_decision` enum('approve','reject','escalate') DEFAULT NULL,
  `signal_breakdown` json DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `resolved_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `proof_of_work_challenges`
-- Manages proof-of-work challenges for high-risk registrations
--

CREATE TABLE `proof_of_work_challenges` (
  `id` int(11) NOT NULL,
  `session_id` varchar(255) NOT NULL,
  `challenge_type` varchar(50) NOT NULL,
  `difficulty` int(11) NOT NULL,
  `target_hash` varchar(64) NOT NULL,
  `nonce` varchar(64) DEFAULT NULL,
  `solution_hash` varchar(64) DEFAULT NULL,
  `completed` tinyint(1) DEFAULT 0,
  `attempts` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expires_at` timestamp NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `disposable_email_domains`
-- Local cache of disposable email domains
--

CREATE TABLE `disposable_email_domains` (
  `id` int(11) NOT NULL,
  `domain` varchar(255) NOT NULL,
  `source` varchar(100) NOT NULL,
  `confidence` decimal(3,2) DEFAULT 1.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ip_reputation`
-- IP reputation data (Tor, VPN, hosting providers)
--

CREATE TABLE `ip_reputation` (
  `id` int(11) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `ip_subnet` varchar(18) NOT NULL,
  `reputation_type` enum('tor','vpn','hosting','proxy','malicious','clean') NOT NULL,
  `confidence` decimal(3,2) DEFAULT 1.00,
  `source` varchar(100) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `evasion_clusters`
-- Groups related evasion attempts for pattern detection
--

CREATE TABLE `evasion_clusters` (
  `id` int(11) NOT NULL,
  `cluster_id` varchar(64) NOT NULL,
  `signal_type` varchar(50) NOT NULL,
  `signal_value` varchar(500) NOT NULL,
  `related_signals` json DEFAULT NULL,
  `cluster_size` int(11) DEFAULT 1,
  `risk_level` enum('low','medium','high','critical') DEFAULT 'low',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_seen` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `rate_limits`
-- Rate limiting for registration attempts
--

CREATE TABLE `rate_limits` (
  `id` int(11) NOT NULL,
  `identifier` varchar(255) NOT NULL,
  `identifier_type` enum('ip','fp_hash','email','subnet') NOT NULL,
  `action` varchar(50) NOT NULL,
  `attempts` int(11) DEFAULT 1,
  `window_start` timestamp NOT NULL DEFAULT current_timestamp(),
  `window_duration` int(11) DEFAULT 3600,
  `blocked_until` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Indexes for dumped tables
--

--
-- Indexes for table `evasion_signals`
--
ALTER TABLE `evasion_signals`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_evasion_signals_user_id` (`user_id`),
  ADD KEY `idx_evasion_signals_session_id` (`session_id`),
  ADD KEY `idx_evasion_signals_normalized_email` (`normalized_email`),
  ADD KEY `idx_evasion_signals_fp_hash` (`fp_hash`),
  ADD KEY `idx_evasion_signals_ip_address` (`ip_address`),
  ADD KEY `idx_evasion_signals_risk_score` (`risk_score`),
  ADD KEY `idx_evasion_signals_created_at` (`created_at`);

--
-- Indexes for table `banned_signals`
--
ALTER TABLE `banned_signals`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_banned_signal` (`signal_type`, `signal_value`),
  ADD KEY `idx_banned_signals_banned_by` (`banned_by`),
  ADD KEY `idx_banned_signals_signal_type` (`signal_type`),
  ADD KEY `idx_banned_signals_severity` (`severity`),
  ADD KEY `idx_banned_signals_created_at` (`created_at`);

--
-- Indexes for table `evasion_attempts`
--
ALTER TABLE `evasion_attempts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_evasion_attempts_session_id` (`session_id`),
  ADD KEY `idx_evasion_attempts_user_id` (`user_id`),
  ADD KEY `idx_evasion_attempts_risk_score` (`risk_score`),
  ADD KEY `idx_evasion_attempts_action_taken` (`action_taken`),
  ADD KEY `idx_evasion_attempts_created_at` (`created_at`);

--
-- Indexes for table `proof_of_work_challenges`
--
ALTER TABLE `proof_of_work_challenges`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_pow_challenges_session_id` (`session_id`),
  ADD KEY `idx_pow_challenges_completed` (`completed`),
  ADD KEY `idx_pow_challenges_expires_at` (`expires_at`);

--
-- Indexes for table `disposable_email_domains`
--
ALTER TABLE `disposable_email_domains`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_domain` (`domain`),
  ADD KEY `idx_disposable_domains_confidence` (`confidence`);

--
-- Indexes for table `ip_reputation`
--
ALTER TABLE `ip_reputation`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_ip_reputation_ip_address` (`ip_address`),
  ADD KEY `idx_ip_reputation_ip_subnet` (`ip_subnet`),
  ADD KEY `idx_ip_reputation_type` (`reputation_type`),
  ADD KEY `idx_ip_reputation_confidence` (`confidence`);

--
-- Indexes for table `evasion_clusters`
--
ALTER TABLE `evasion_clusters`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_evasion_clusters_cluster_id` (`cluster_id`),
  ADD KEY `idx_evasion_clusters_signal_type` (`signal_type`),
  ADD KEY `idx_evasion_clusters_risk_level` (`risk_level`);

--
-- Indexes for table `rate_limits`
--
ALTER TABLE `rate_limits`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_rate_limits_identifier` (`identifier`, `identifier_type`),
  ADD KEY `idx_rate_limits_action` (`action`),
  ADD KEY `idx_rate_limits_window_start` (`window_start`);

-- --------------------------------------------------------

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `evasion_signals`
--
ALTER TABLE `evasion_signals`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `banned_signals`
--
ALTER TABLE `banned_signals`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `evasion_attempts`
--
ALTER TABLE `evasion_attempts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `proof_of_work_challenges`
--
ALTER TABLE `proof_of_work_challenges`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `disposable_email_domains`
--
ALTER TABLE `disposable_email_domains`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ip_reputation`
--
ALTER TABLE `ip_reputation`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `evasion_clusters`
--
ALTER TABLE `evasion_clusters`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `rate_limits`
--
ALTER TABLE `rate_limits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

-- --------------------------------------------------------

--
-- Constraints for dumped tables
--

--
-- Constraints for table `evasion_signals`
--
ALTER TABLE `evasion_signals`
  ADD CONSTRAINT `evasion_signals_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `banned_signals`
--
ALTER TABLE `banned_signals`
  ADD CONSTRAINT `banned_signals_ibfk_1` FOREIGN KEY (`banned_by`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `evasion_attempts`
--
ALTER TABLE `evasion_attempts`
  ADD CONSTRAINT `evasion_attempts_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;
