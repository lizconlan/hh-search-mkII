create table `contributions` (
  `id` int(11) NOT NULL auto_increment,
  `sitting_title` text NOT NULL,
  `date` datetime NOT NULL,
  `slug` varchar(128) NOT NULL,
  `anchor_id` varchar(128) NOT NULL,
  `sitting_type` varchar(128) NOT NULL,
  `column_range` varchar(255) NULL,
  `person_id` int(11) NULL,
  PRIMARY KEY  (`id`),
  INDEX `date_index` (`date`),
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table `people` (
  `id` int(11) NOT NULL auto_increment,
  `honorific` varchar(128) NOT NULL,
  `name` varchar(255) NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `lastname` varchar(128) NOT NULL,
  `slug` varchar(128) NULL,
  PRIMARY KEY  (`id`),
  INDEX `lastname_index` (`lastname`),
  INDEX `full_name_index` (`full_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table `sections` (
  `id` int(11) NOT NULL auto_increment,
  `date` datetime NOT NULL,
  `volume` int(11) NOT NULL,
  `sitting_type` varchar(128) NOT NULL,
  `section_type` varchar(128) NULL,
  `start_column` int(11) NOT NULL,
  `end_column` int(11) NULL,
  `slug` varchar(128) NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;