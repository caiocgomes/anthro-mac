extension Migrations {
    /// Versão 2: crianças, visitas, mães, pais e endereços da Avaliação individual (design D1 da add-individual-assessment).
    public static let individual = Migration(
        version: 2,
        name: "individual",
        sql: """
        CREATE TABLE mothers(
            mother_id INTEGER PRIMARY KEY AUTOINCREMENT,
            first_name TEXT, last_name TEXT, height TEXT, weight TEXT,
            date_of_birth TEXT, date_of_birth_is_approx INTEGER NOT NULL DEFAULT 0, notes TEXT,
            created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
            updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
        );
        CREATE TABLE fathers(
            father_id INTEGER PRIMARY KEY AUTOINCREMENT,
            first_name TEXT, last_name TEXT, height TEXT, weight TEXT,
            date_of_birth TEXT, date_of_birth_is_approx INTEGER NOT NULL DEFAULT 0, notes TEXT,
            created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
            updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
        );
        CREATE TABLE addresses(
            address_id INTEGER PRIMARY KEY AUTOINCREMENT,
            street_info TEXT, place TEXT, zip TEXT, district TEXT, province TEXT, state TEXT, country TEXT,
            phone_number TEXT, email TEXT,
            created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
            updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
        );
        CREATE TABLE children(
            child_id INTEGER PRIMARY KEY AUTOINCREMENT,
            display_id INTEGER,
            first_name TEXT, last_name TEXT,
            date_of_birth TEXT NOT NULL,
            date_of_birth_is_approx INTEGER NOT NULL DEFAULT 0,
            sex INTEGER NOT NULL CHECK (sex IN (1, 2)),
            mother_id INTEGER REFERENCES mothers(mother_id) ON DELETE SET NULL,
            father_id INTEGER REFERENCES fathers(father_id) ON DELETE SET NULL,
            address_id INTEGER REFERENCES addresses(address_id) ON DELETE SET NULL,
            notes TEXT, follow_up_date TEXT, follow_up_interval INTEGER, follow_up_ref_to TEXT,
            is_archived INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
            updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
        );
        CREATE INDEX children_archived_display ON children(is_archived, display_id);
        CREATE TABLE visits(
            child_id INTEGER NOT NULL REFERENCES children(child_id) ON DELETE CASCADE,
            date TEXT NOT NULL,
            weight TEXT, height TEXT,
            is_recumbent INTEGER NOT NULL DEFAULT 0,
            has_oedema INTEGER NOT NULL DEFAULT 0,
            notes TEXT, additional_data TEXT,
            created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
            updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
            PRIMARY KEY (child_id, date)
        );
        """
    )
}
