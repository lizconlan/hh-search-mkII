create table `contributions` (
  `id` int(11) NOT NULL auto_increment,
  `sitting_title` text NOT NULL,
  `date` datetime NOT NULL,
  `slug` varchar(64) NOT NULL,
  `anchor_id` varchar(64) NOT NULL,
  `sitting_type` varchar(128) NOT NULL,
  `start_column` varchar(32) NULL,
  `end_column` varchar(32) NULL,
  `volume` int(11) NOT NULL,
  `part` int(11) NOT NULL,
  `series` int(11) NOT NULL,
  `house` varchar(16),
  `question_no` varchar(32) NULL,
  `question_subject` text NULL,
  `person_id` int(11) NULL,
  PRIMARY KEY  (`id`),
  INDEX `date_index` (`date`),
  INDEX `sittype_index` (`sitting_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table `people` (
  `id` int(11) NOT NULL auto_increment,
  `honorific` varchar(128) NOT NULL,
  `name` varchar(255) NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `lastname` varchar(128) NOT NULL,
  `slug` varchar(128) NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;