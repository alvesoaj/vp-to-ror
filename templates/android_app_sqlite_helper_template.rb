module AndroidAppSQLiteHelperTemplate
    def self.build(package, table_creations, table_commands)
        res = ""
        res += "package " + package + ".utils;\n\n"

        res += "import android.content.Context;\n"
        res += "import android.database.sqlite.SQLiteDatabase;\n"
        res += "import android.database.sqlite.SQLiteOpenHelper;\n"
        res += "import android.util.Log;\n\n"

        res += "public class AppSQLiteHelper extends SQLiteOpenHelper {\n"
        res += "    /**\n"
        res += "     *\n"
        res += "     */\n\n"

        res += "    private static final String DATABASE_NAME = \"" + package.split(".").last + ".db\";\n"
        res += "    private static final int DATABASE_VERSION = 1;\n\n"

        res +=      table_creations

        res += "    public AppSQLiteHelper(Context context) {\n"
        res += "        super(context, DATABASE_NAME, null, DATABASE_VERSION);\n"
        res += "    }\n\n"

        res += "    @Override\n"
        res += "    public void onCreate(SQLiteDatabase database) {\n"
        res += "        // version 1\n"
        res +=          table_commands
        res += "    }\n\n"

        res += "    @Override\n"
        res += "    public void onUpgrade(SQLiteDatabase database, int oldVersion, int newVersion) {\n"
        res += "        Log.w(" + package + ".utils.AppSQLiteHelper.class.getName(), \"Upgrading database from version \" + oldVersion + \" to \" + newVersion + \".\");\n\n"

        res += "        for (int i = oldVersion; i < newVersion; i++) {\n"
        res += "            switch (i) {\n"
        res += "            }\n"
        res += "        }\n"
        res += "    }\n"
        res += "}\n"

        return res
    end
end