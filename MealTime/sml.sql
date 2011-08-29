

CREATE TABLE "photos" (
"id" INTEGER PRIMARY KEY ON CONFLICT IGNORE AUTOINCREMENT,
"biz" TEXT,
"src" TEXT UNIQUE,
"caption" TEXT,
"width" INTEGER,
"height" INTEGER
);


CREATE TABLE "places" (
"id" INTEGER PRIMARY KEY ON CONFLICT IGNORE AUTOINCREMENT,
"biz" TEXT UNIQUE ON CONFLICT REPLACE,
"name" TEXT,
"rating" REAL,
"phone" TEXT,
"numreviews" INTEGER,
"price" TEXT,
"category" TEXT,
"distance" REAL,
"city" TEXT,
"address" TEXT,
"coordinates" TEXT,
"hours" TEXT,
"numphotos" INTEGER
);


CREATE TABLE "reviews" (
"id" INTEGER PRIMARY KEY ON CONFLICT IGNORE AUTOINCREMENT,
"srid" TEXT UNIQUE,
"excerpt" TEXT
);
