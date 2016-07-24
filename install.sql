CREATE DATABASE `rocketblog` /*!40100 DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci */;

CREATE TABLE `category` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `url` varchar(255) NOT NULL,
  `order` int(11) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

CREATE TABLE `image` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(256) DEFAULT NULL,
  `url` varchar(256) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

CREATE TABLE `tag` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `url` varchar(255) NOT NULL,
  `order` int(11) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;


CREATE TABLE `article` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `url` varchar(255) NOT NULL,
  `url_old` varchar(255) DEFAULT NULL,
  `date` datetime NOT NULL,
  `intro` text,
  `full` text,
  `img_id` int(11) DEFAULT NULL,
  `img_sm_id` int(11) DEFAULT NULL,
  `published` tinyint(1) NOT NULL DEFAULT '0',
  `starred` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `url` (`url`),
  KEY `img_id` (`img_id`),
  KEY `img_sm_id` (`img_sm_id`),
  CONSTRAINT `img_id` FOREIGN KEY (`img_id`) REFERENCES `image` (`id`),
  CONSTRAINT `img_sm_id` FOREIGN KEY (`img_sm_id`) REFERENCES `image` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

CREATE TABLE `article_category` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `article_id` int(11) NOT NULL,
  `category_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `article_category_uniq` (`article_id`,`category_id`),
  KEY `article_category_article_id` (`article_id`),
  KEY `article_category_category_id` (`category_id`),
  CONSTRAINT `article_category_article_id_refs` FOREIGN KEY (`article_id`) REFERENCES `article` (`id`),
  CONSTRAINT `article_category_category_id_refs` FOREIGN KEY (`category_id`) REFERENCES `category` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

CREATE TABLE `article_tag` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `article_id` int(11) NOT NULL,
  `tag_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `article_tag_uniq` (`article_id`,`tag_id`),
  KEY `article_id` (`article_id`),
  KEY `tag_id` (`tag_id`),
  CONSTRAINT `article_id_refs` FOREIGN KEY (`article_id`) REFERENCES `article` (`id`),
  CONSTRAINT `tag_id_refs` FOREIGN KEY (`tag_id`) REFERENCES `tag` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;


ALTER TABLE `article`
ADD COLUMN `video` VARCHAR(45) NULL DEFAULT NULL AFTER `img_sm_id`;

ALTER TABLE `tag`
ADD COLUMN `parent` INT(11) NULL DEFAULT NULL AFTER `order`;

CREATE TABLE `location` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) NOT NULL,
  `url` varchar(255) NOT NULL,
  `order` int(11) DEFAULT '0',
  `parent` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

CREATE TABLE `article_location` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `article_id` int(11) NOT NULL,
  `location_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `article_location_uniq` (`article_id`,`location_id`),
  KEY `article_id` (`article_id`),
  KEY `location_id` (`location_id`),
  CONSTRAINT `article_location_id_refs` FOREIGN KEY (`article_id`) REFERENCES `article` (`id`),
  CONSTRAINT `location_id_refs` FOREIGN KEY (`location_id`) REFERENCES `location` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

ALTER TABLE `tag`
DROP COLUMN `parent`;






