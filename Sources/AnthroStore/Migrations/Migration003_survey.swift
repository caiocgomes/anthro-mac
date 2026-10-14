extension Migrations {
    /// Versão 3: inquéritos e registros do Inquérito nutricional (design D3 da add-nutritional-survey).
    /// `has_oedema` aceita NULL (`Records.HasOedema` é `bool?`); `position` guarda a ordem de inclusão.
    public static let survey = Migration(
        version: 3,
        name: "survey",
        sql: """
        CREATE TABLE surveys(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            notes TEXT,
            additional_data_def TEXT,
            options TEXT NOT NULL,
            is_archived INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
            updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
        );
        CREATE TABLE records(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            survey_id INTEGER NOT NULL REFERENCES surveys(id) ON DELETE CASCADE,
            position INTEGER NOT NULL,
            visit_date TEXT,
            cluster INTEGER, team INTEGER, display_id INTEGER, household INTEGER,
            weighting_factor TEXT NOT NULL,
            first_name TEXT, last_name TEXT,
            date_of_birth TEXT,
            dob_is_approx INTEGER NOT NULL,
            age_months TEXT,
            sex INTEGER NOT NULL CHECK (sex IN (1, 2)),
            weight TEXT, length_or_height TEXT,
            measured_recumbent INTEGER NOT NULL,
            has_oedema INTEGER,
            notes TEXT, additional_data TEXT,
            created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
            updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now'))
        );
        CREATE INDEX records_survey_position ON records(survey_id, position);
        """
    )
}
