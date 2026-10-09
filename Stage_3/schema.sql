-- Mezyad revised proposal, 2026-10-10. MySQL 8.4 / InnoDB.
-- Replaces the earlier PostgreSQL draft. Not executed against MySQL or deployed.
-- DATETIME values are UTC. Python uses Decimal for money, not float.
-- Flask signed-cookie sessions do not require a user_sessions table.

CREATE TABLE users (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(120) NOT NULL,
 email VARCHAR(254) NOT NULL UNIQUE,
 password_hash VARCHAR(255) NOT NULL,
 role VARCHAR(10) NOT NULL,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 CHECK (CHAR_LENGTH(TRIM(name)) > 0),
 CHECK (role IN ('BIDDER','SELLER','ADMIN'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE categories (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 code VARCHAR(30) NOT NULL UNIQUE,
 name VARCHAR(80) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE items (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 seller_id INT UNSIGNED NOT NULL,
 category_id INT UNSIGNED NOT NULL,
 title VARCHAR(200) NOT NULL,
 description TEXT NOT NULL,
 location VARCHAR(150),
 category_fields JSON NOT NULL,
 status VARCHAR(20) NOT NULL DEFAULT 'PENDING_REVIEW',
 reviewed_by INT UNSIGNED,
 reviewed_at DATETIME(6),
 review_notes TEXT,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 FOREIGN KEY (seller_id) REFERENCES users(id) ON DELETE RESTRICT,
 FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT,
 FOREIGN KEY (reviewed_by) REFERENCES users(id) ON DELETE RESTRICT,
 CHECK (CHAR_LENGTH(TRIM(title)) > 0),
 CHECK (CHAR_LENGTH(TRIM(description)) > 0),
 CHECK (JSON_TYPE(category_fields) = 'OBJECT'),
 CHECK (status IN ('PENDING_REVIEW','APPROVED','REJECTED')),
 CHECK ((status = 'PENDING_REVIEW' AND reviewed_by IS NULL AND reviewed_at IS NULL)
     OR (status IN ('APPROVED','REJECTED') AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)),
 CHECK (status <> 'REJECTED' OR (review_notes IS NOT NULL AND CHAR_LENGTH(TRIM(review_notes)) > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE item_images (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 item_id INT UNSIGNED NOT NULL,
 image_path VARCHAR(255) NOT NULL,
 display_order INT UNSIGNED NOT NULL,
 FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT,
 UNIQUE (item_id,display_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE auctions (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 item_id INT UNSIGNED NOT NULL UNIQUE,
 visibility VARCHAR(10) NOT NULL,
 access_code_hash VARCHAR(255),
 status VARCHAR(10) NOT NULL DEFAULT 'SCHEDULED',
 starting_price DECIMAL(18,2) NOT NULL,
 current_price DECIMAL(18,2),
 minimum_increment DECIMAL(18,2) NOT NULL,
 anti_sniping_seconds INT UNSIGNED NOT NULL DEFAULT 60,
 start_time DATETIME(6) NOT NULL,
 end_time DATETIME(6) NOT NULL,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 FOREIGN KEY (item_id) REFERENCES items(id) ON DELETE RESTRICT,
 CHECK (visibility IN ('PUBLIC','PRIVATE')),
 CHECK (status IN ('SCHEDULED','ACTIVE','CLOSED')),
 CHECK (starting_price > 0 AND minimum_increment > 0),
 CHECK (anti_sniping_seconds > 0),
 CHECK (current_price IS NULL OR current_price >= starting_price),
 CHECK (end_time > start_time),
 CHECK ((visibility = 'PUBLIC' AND access_code_hash IS NULL)
     OR (visibility = 'PRIVATE' AND access_code_hash IS NOT NULL AND CHAR_LENGTH(TRIM(access_code_hash)) > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE private_auction_access (
 auction_id INT UNSIGNED NOT NULL,
 user_id INT UNSIGNED NOT NULL,
 granted_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 PRIMARY KEY (auction_id,user_id),
 FOREIGN KEY (auction_id) REFERENCES auctions(id) ON DELETE RESTRICT,
 FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE bid_commitments (
 auction_id INT UNSIGNED NOT NULL,
 bidder_id INT UNSIGNED NOT NULL,
 status VARCHAR(10) NOT NULL,
 created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
 PRIMARY KEY (auction_id,bidder_id),
 FOREIGN KEY (auction_id) REFERENCES auctions(id) ON DELETE RESTRICT,
 FOREIGN KEY (bidder_id) REFERENCES users(id) ON DELETE RESTRICT,
 CHECK (status IN ('COMMITTED','REJECTED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE bids (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 auction_id INT UNSIGNED NOT NULL,
 bidder_id INT UNSIGNED NOT NULL,
 amount DECIMAL(18,2) NOT NULL,
 request_id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 created_at DATETIME(6) NOT NULL,
 FOREIGN KEY (auction_id) REFERENCES auctions(id) ON DELETE RESTRICT,
 FOREIGN KEY (bidder_id) REFERENCES users(id) ON DELETE RESTRICT,
 FOREIGN KEY (auction_id,bidder_id) REFERENCES bid_commitments(auction_id,bidder_id) ON DELETE RESTRICT,
 UNIQUE (auction_id,bidder_id,request_id),
 UNIQUE (auction_id,amount),
 UNIQUE (auction_id,id),
 CHECK (amount > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE auction_results (
 auction_id INT UNSIGNED PRIMARY KEY,
 winning_bid_id INT UNSIGNED,
 closed_at DATETIME(6) NOT NULL,
 FOREIGN KEY (auction_id) REFERENCES auctions(id) ON DELETE RESTRICT,
 FOREIGN KEY (auction_id,winning_bid_id) REFERENCES bids(auction_id,id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Server checks remain necessary: roles, ownership, approved item, PRIVATE grant,
-- COMMITTED status, amount/time, extension, highest-bid selection.
-- Bid/extension/close writers lock the same auction row inside a transaction.
-- The closing transaction writes exactly one result; NULL winner only if no bids.
-- No endpoint accepts a manually chosen winning_bid_id.
