module AndroidDAOTemplate
    def self.build(table_ref, obj_ref, obj_arr_ref, package, dao_consts, dao_const_arr, dao_put_obj, dao_cur_list)
        res = ""
        res += "package " + package + ".daos;\n\n"

        res += "import android.content.ContentValues;\n"
        res += "import android.content.Context;\n"
        res += "import android.database.Cursor;\n"
        res += "import android.database.SQLException;\n"
        res += "import android.database.sqlite.SQLiteDatabase;\n\n"

        res += "import java.util.ArrayList;\n"
        res += "import java.util.Locale;\n\n"

        res += "import " + package + ".models." + table_ref + ";\n"
        res += "import " + package + ".utils.AppHelper;\n"
        res += "import " + package + ".utils.AppSQLiteHelper;\n\n"

        res += "public class " + table_ref + "DAO {\n"
        res += "    /**\n"
        res += "     *\n"
        res += "     */\n\n"

        res +=      dao_consts

        res +=      dao_const_arr

        res += "    private SQLiteDatabase database;\n"
        res += "    private AppSQLiteHelper dbHelper;\n\n"

        res += "    public " + table_ref + "DAO(Context context) {\n"
        res += "        dbHelper = new AppSQLiteHelper(context);\n"
        res += "    }\n\n"

        res += "    public void open() throws SQLException {\n"
        res += "        database = dbHelper.getWritableDatabase();\n"
        res += "        // to activate foreign keys and its trigers\n"
        res += "        // database.execSQL(\"PRAGMA foreign_keys=ON;\");\n"
        res += "    }\n\n"

        res += "    public void close() {\n"
        res += "        dbHelper.close();\n"
        res += "    }\n\n"

        res += "    public long create(" + table_ref + " " + obj_ref + ") {\n"
        res += "        return database.insert(TABLE_NAME, null, buildArguments(" + obj_ref + "));\n"
        res += "    }\n\n"

        res += "    public int update(" + table_ref + " " + obj_ref + ") {\n"
        res += "        ContentValues values = buildArguments(" + obj_ref + ");\n"
        res += "        return database.update(TABLE_NAME, values,\n"
        res += "                String.format(Locale.getDefault(), \"%s = %d\", ID, " + obj_ref + ".getId()), null);\n"
        res += "    }\n\n"

        res += "    private ContentValues buildArguments(" + table_ref + " " + obj_ref + ") {\n"
        res += "        ContentValues values = new ContentValues();\n\n"

        res +=          dao_put_obj

        res += "        return values;\n"
        res += "    }\n\n"

        res += "    public void delete(Long id) {\n"
        res += "        database.delete(TABLE_NAME, String.format(Locale.getDefault(), \"%s = %d\", ID, id), null);\n"
        res += "    }\n\n"

        res += "    public " + table_ref + " selectById(Long id) {\n"
        res += "        Cursor cursor = database.query(TABLE_NAME, ALL_COLUMNS,\n"
        res += "                String.format(Locale.getDefault(), \"%s = %d\", ID, id), null, null, null, null);\n\n"

        res += "        " + table_ref + " " + obj_ref + " = null;\n"
        res += "        if (cursor.moveToFirst()) {\n"
        res += "            " + obj_ref + " = cursorToList(cursor);\n"
        res += "        }\n"
        res += "        cursor.close();\n"
        res += "        return " + obj_ref + ";\n"
        res += "    }\n\n"

        res += "    public ArrayList<" + table_ref + "> selectAll() {\n"
        res += "        ArrayList<" + table_ref + "> " + obj_arr_ref + " = new ArrayList<>();\n\n"

        res += "        Cursor cursor = database.query(TABLE_NAME, ALL_COLUMNS, null, null, null,\n"
        res += "                null, null);\n"
        res += "        cursor.moveToFirst();\n\n"

        res += "        while (!cursor.isAfterLast()) {\n"
        res += "            " + table_ref + " " + obj_ref + " = cursorToList(cursor);\n"
        res += "            " + obj_arr_ref + ".add(" + obj_ref + ");\n"
        res += "            cursor.moveToNext();\n"
        res += "        }\n"
        res += "        cursor.close();\n\n"

        res += "        return " + obj_arr_ref + ";\n"
        res += "    }\n\n"

        res += "    public static " + table_ref + " cursorToList(Cursor cursor) {\n"
        res += "        " + table_ref + " " + obj_ref + " = new " + table_ref + "();\n\n"

        res +=          dao_cur_list

        res += "\n        return " + obj_ref + ";\n"
        res += "    }\n\n"

        res += "    public " + table_ref + " save(" + table_ref + " origin) {\n"
        res += "        " + table_ref + " destiny = selectById(origin.getId());\n"
        res += "        if (destiny != null && origin.getId().equals(destiny.getId())) {\n"
        res += "            if (origin.getUpdatedAt().compareTo(destiny.getUpdatedAt()) > 0) {\n"
        res += "                update(origin);\n"
        res += "            }\n"
        res += "        } else {\n"
        res += "            // if auto increment model, get id here\n"
        res += "            create(origin);\n"
        res += "        }\n"
        res += "        return origin;\n"
        res += "    }\n"
        res += "}\n"

        return res
    end
end