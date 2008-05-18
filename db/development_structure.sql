CREATE TABLE `contacts` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) NOT NULL,
  `position` int(11) NOT NULL default '0',
  `locationtype` varchar(63) default NULL,
  `preference` varchar(255) NOT NULL default '',
  `organization` varchar(255) default NULL,
  `jobtitle` varchar(255) default NULL,
  `address` varchar(255) default NULL,
  `address2` varchar(255) default NULL,
  `city` varchar(255) default NULL,
  `province` varchar(255) default NULL,
  `country` varchar(255) default NULL,
  `postal` varchar(255) default NULL,
  `phone1` varchar(63) default NULL,
  `phone1_type` varchar(1) default NULL,
  `phone2` varchar(63) default NULL,
  `phone2_type` varchar(1) default NULL,
  `phone3` varchar(63) default NULL,
  `phone3_type` varchar(1) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_contacts_on_user_id_and_position` (`user_id`,`position`),
  KEY `index_contacts_on_country_and_province_and_city` (`country`,`province`,`city`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Basic user record for login.';

CREATE TABLE `db_files` (
  `id` int(11) NOT NULL auto_increment,
  `data` longblob,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COMMENT='attachment_fu database file storage.';

CREATE TABLE `documents` (
  `id` int(11) NOT NULL auto_increment,
  `db_file_id` int(11) default NULL,
  `user_id` int(11) NOT NULL,
  `parent_id` int(11) default NULL,
  `type` varchar(255) default NULL,
  `subfolder` varchar(255) default NULL,
  `content_type` varchar(255) NOT NULL,
  `filename` varchar(255) NOT NULL,
  `thumbnail` varchar(255) default NULL,
  `size` int(11) NOT NULL,
  `width` int(11) default NULL,
  `height` int(11) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_documents_on_user_id` (`user_id`),
  KEY `index_documents_on_parent_id` (`parent_id`),
  KEY `type` (`type`,`thumbnail`,`user_id`),
  KEY `filename` (`filename`),
  KEY `thumbnail` (`thumbnail`,`type`,`user_id`),
  KEY `index_documents_on_size` (`size`),
  KEY `index_documents_on_created_at` (`created_at`),
  KEY `thumbnail_filename` (`thumbnail`,`type`,`filename`),
  KEY `type_filename` (`type`,`thumbnail`,`filename`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COMMENT='Metadata for files.';

CREATE TABLE `email_changes` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) default NULL,
  `email` varchar(255) default NULL,
  `activation_code` varchar(40) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `index_email_changes_on_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Pending change email requests for users.';

CREATE TABLE `items` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) default NULL,
  `editor_id` int(11) default NULL,
  `parent_id` int(11) default NULL,
  `subpath` varchar(255) default NULL,
  `sitepath` text,
  `title` varchar(255) default NULL,
  `description` varchar(255) default NULL,
  `content` longtext,
  `content_type` varchar(255) default NULL,
  `keywords` varchar(255) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `user` (`user_id`,`title`),
  KEY `parent` (`parent_id`,`title`),
  KEY `title` (`title`,`content_type`),
  KEY `sitepath` (`sitepath`(255))
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Core data object.';

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL auto_increment,
  `from` varchar(255) default NULL,
  `to` varchar(255) default NULL,
  `last_send_attempt` int(11) default '0',
  `mail` text,
  `created_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_notifications_on_last_send_attempt` (`last_send_attempt`),
  KEY `index_notifications_on_created_at` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COMMENT='Outbound email messages (ar_mailer).';

CREATE TABLE `schema_info` (
  `version` int(11) default NULL
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

CREATE TABLE `sessions` (
  `id` int(11) NOT NULL auto_increment,
  `session_id` varchar(255) NOT NULL,
  `data` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_sessions_on_session_id` (`session_id`),
  KEY `index_sessions_on_updated_at` (`updated_at`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=utf8 COMMENT='User sessions.';

CREATE TABLE `users` (
  `id` int(11) NOT NULL auto_increment,
  `email` varchar(255) default NULL,
  `activation_code` varchar(40) default NULL,
  `activated_at` datetime default NULL,
  `crypted_password` varchar(40) default NULL,
  `salt` varchar(40) default NULL,
  `nickname` varchar(255) default NULL,
  `fullname` varchar(255) default NULL,
  `admin` tinyint(1) default NULL,
  `staff` tinyint(1) default NULL,
  `remember_token` varchar(255) default NULL,
  `remember_token_expires_at` datetime default NULL,
  `subpath` varchar(31) default NULL,
  `location` varchar(255) default NULL,
  `about` text,
  `login_at` datetime default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `index_users_on_email` (`email`),
  UNIQUE KEY `index_users_on_nickname` (`nickname`),
  UNIQUE KEY `index_users_on_remember_token` (`remember_token`),
  UNIQUE KEY `index_users_on_subpath` (`subpath`),
  KEY `index_users_on_staff` (`staff`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COMMENT='Basic user record for login.';

INSERT INTO `schema_info` (version) VALUES (5)