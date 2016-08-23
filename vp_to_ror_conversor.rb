require "nokogiri"
require "active_support/inflector" # para usar camelize, singularize e upcase
require "yaml" # ler documentos YML
load "table.rb"
load "column.rb"
require "./templates/android_app_sqlite_helper_template"
require "./templates/android_model_template"
require "./templates/android_dao_template"

config = YAML.load_file("config.yml")

vp_file = config["config"]["file_path"]
android_package = config["config"]["android_package"]
time_now = DateTime.parse(config["config"]["migration_datetime"]).to_time

def delete_matching_regexp(dir, regex)
    Dir.entries(dir).each do |name|
        path = File.join(dir, name)
        if name =~ regex
            ftype = File.directory?(path) ? Dir : File
            begin
                ftype.delete(path)
            rescue SystemCallError => e
                $stderr.puts e.message
            end
        end
    end
end

delete_matching_regexp("rails", /.rb$/)
delete_matching_regexp("android", /.java$/)

break + 23

# parseando o arquivo
doc = File.open(vp_file) { |f| Nokogiri::XML(f) }

# pegando as tabelas que contem no arquivo
tables_doc = doc.xpath("/Project/Models/DBTable")

tables = []

tables_doc.each do |table_doc|
    table = Table.new(table_doc["Id"], table_doc["Name"])

    columns_doc = table_doc.xpath("*/DBColumn")

    columns_doc.each do |column_doc|
        foreign_doc = column_doc.xpath("*/DBForeignKeyConstraint").first
        
        is_fk = nil
        if !foreign_doc.nil?
            is_fk = foreign_doc["RefColumn"]
        end
        
        table.add_column(Column.new(column_doc["Id"], column_doc["Name"], column_doc["Type"], column_doc["Length"], column_doc["PrimaryKey"], is_fk, column_doc["Index"], column_doc["Unique"], column_doc["Nullable"], column_doc["DefaultValue"]))
    end

    tables << table
end

tables.each do |table|
    table.columns.each do |column|
        if !column.is_fk.nil?
            tables.each do |t|
                t.columns.each do |c|
                    if column.is_fk == c.id
                        column.ref = t.name.singularize
                        !column.is_null ? t.associations_d << table.name : t.associations_n << table.name
                        break
                    end
                end
            end
        end
    end
end

# CRIANDO OS ARQUIVOS RAILS

cmds_p = ""
cmds_r = ""
cmds_g = ""

index_view = "<h2>Hello to my WEBSERVICE!</h2>\n\n"

tables.each do |table|
    if table.name != "default"
        index_view += "<%= link_to :" + table.name + ", " + table.name + "_path %></br>\n"

        file_mig = File.open("rails/migrate/" + time_now.strftime("%Y%m%d%H%M%S") + "_create_" + table.name + ".rb", "w")
        file_mdl = File.open("rails/models/" + table.name.singularize + ".rb", "w")

        cmds_p += "resources :" + table.name + "\n"
        cmds_r += "rails destroy scaffold_controller " + table.name.singularize + " && "
        cmds_g += "rails generate scaffold_controller " + table.name.singularize

        txt_mig = ""
        txt_mig += "class Create" + table.name.camelize + " < ActiveRecord::Migration\n"
        txt_mig += "    def change\n"
        txt_mig += "        create_table :" + table.name + " do |t|\n"

        txt_mdl = ""
        txt_mdl = "class " + table.name.singularize.camelize + " < ActiveRecord::Base\n"
        
        txt_mdl_rels = "    ##### RELATIONSHIPS\n"
        txt_mdl_vals = "    ##### VALIDATIONS\n"

        # iterar todas as associações para remover em cascata
        table.associations_d.each do |association|
            txt_mdl_rels += "    has_many :" + association + ", dependent: :destroy\n"
            txt_mdl_vals += "    validates_associated :" + association + "\n"
        end

        # iterar todas as associações para anular em cascata
        table.associations_n.each do |association|
            txt_mdl_rels += "    has_many :" + association + ", dependent: :nullify\n"
            txt_mdl_vals += "    validates_associated :" + association + "\n"
        end

        table.columns.each do |column|
            if column.name != "id" && column.name != "created_at" && column.name != "updated_at"
                type = (!column.ref.nil? ? "belongs_to" : column.ruby_type)
                name = (!column.ref.nil? ? column.ref : column.name)

                # Se a coluna tiver uma referência, for chave estrangeira
                if !column.ref.nil?
                    txt_mdl_rels += "    belongs_to :" + column.ref + "\n"

                    # Se a coluna além de ser chave estrangeira, não puder ser nula e não tiver valor padrão
                    if !column.is_null && column.def_val.nil?
                        txt_mdl_vals += "    validates :" + column.ref + ", presence: true\n"
                    end
                end

                # Se a coluna não puder ser nula, não tiver valor padão, e não for chave estrangeira
                if !column.is_null && column.def_val.nil? && column.ref.nil?
                    txt_mdl_vals += "    validates :" + name + ", presence: true\n"
                end

                # se a coluna tiver de ser única e não for chave estrangeira
                if column.is_unique && column.ref.nil?
                    txt_mdl_vals += "    validates :" + name + ", uniqueness: true" + (column.is_null ? ", allow_nil: true" : "") + "\n"
                end

                txt_mig += "            t." + type + " :" + name + (", index: true" if column.is_index).to_s + (", foreign_key: true" if !column.ref.nil?).to_s + (", null: false" if !column.is_null).to_s + (", unique: true" if column.is_unique).to_s + (", default: " + column.def_val.to_s if !column.def_val.nil?).to_s + "\n"
                
                cmds_g += " " + name + ":" + type
            end
        end

        txt_mdl += txt_mdl_rels + "\n" + txt_mdl_vals
        txt_mdl += "end\n"

        txt_mig += "\n"
        txt_mig += "            t.timestamps null: false\n"
        txt_mig += "        end\n"
        txt_mig += "    end\n"
        txt_mig += "end\n"

        cmds_g += " --no-jbuilder && "

        file_mdl.write(txt_mdl)
        file_mig.write(txt_mig)

        time_now += 1
    end
end

cmds_p += "\nroot \"pages#index\""

File.write("rails/output.txt", "##### ROUTES\n" + cmds_p + "\n\n##### DESTROYERS\n" + cmds_r + "\n\n##### GENERATORS\n" + cmds_g)

File.write("rails/controllers/pages_controller.rb", "class PagesController < ApplicationController\n    def index\n    end\nend")

Dir.mkdir("rails/views/pages") unless File.exists?("rails/views/pages")

File.write("rails/views/pages/index.html.erb", index_view)


# MONTANTO OS ARQUIVOS ANDROID

sqlite_hel_tab_cri = ""
sqlite_hel_tab_cmd = ""

tables.each do |table|
    if table.name != "default"
        sqlite_hel_tab_cri += "    private static final String CREATE_" + table.name.upcase + "_TABLE = \"CREATE TABLE [" + table.name + "] ( \"\n"
        
        attributes_txt = ""
        get_and_set_txt = ""

        dao_consts = "    public static final String TABLE_NAME = \"" + table.name + "\";\n"
        dao_const_arr = "\n    public static final String[] ALL_COLUMNS = {"
        dao_put_obj = ""
        dao_cur_list = ""
        
        table.columns.each_with_index do |column, index|
            sqlite_hel_tab_cri += "        + \" [" + column.name + "] " + column.sqlite_type + (column.is_pk ? " PRIMARY KEY AUTOINCREMENT" : "") + (!column.is_null ? " NOT NULL" : "") + (column.is_unique ? " UNIQUE" : "")
            
            if index < table.columns.size - 1
                sqlite_hel_tab_cri += ",\"\n"
            else
                sqlite_hel_tab_cri += ");\";\n\n"
            end

            attributes_txt += "    private " + column.java_type + " " + column.name.camelize(:lower) + ";\n"

            get_and_set_txt += "\n    public " + column.java_type + " get" + column.name.camelize + "() {\n"
            get_and_set_txt += "        return " + column.name.camelize(:lower) + ";\n"
            get_and_set_txt += "    }\n\n"

            get_and_set_txt += "    public void set" + column.name.camelize + "(" + column.java_type + " " + column.name.camelize(:lower) + ") {\n"
            get_and_set_txt += "        this." + column.name.camelize(:lower) + " = " + column.name.camelize(:lower) + ";\n"
            get_and_set_txt += "    }\n"

            dao_consts += "    public static final String " + column.name.upcase + " = \"" + column.name + "\";\n"
        
            dao_const_arr += column.name.upcase

            if index < table.columns.size - 1
                dao_const_arr += ", "
            else
                dao_const_arr += "};\n\n"
            end

            dao_put_obj += "        values.put(" + column.name.upcase + ", " + (column.java_type == "Date" ? "AppHelper.getFormattedData(" : "") + table.name.singularize + ".get" + column.name.camelize + "()"  + (column.java_type == "Date" ? ")" : "") + ");\n"
            
            dao_cur_list += "        " + table.name.singularize + ".set" + column.name.camelize + "(" + column.get_java_type_in_conversor(index) + ");\n"
        end
        
        File.write("android/models/" + table.name.singularize.camelize + ".java", AndroidModelTemplate.build(table.name.singularize.camelize, android_package, attributes_txt, get_and_set_txt))
        File.write("android/daos/" + table.name.singularize.camelize + "DAO.java", AndroidDAOTemplate.build(table.name.singularize.camelize, table.name.singularize, table.name, android_package, dao_consts, dao_const_arr, dao_put_obj, dao_cur_list))

        sqlite_hel_tab_cmd += "        database.execSQL(CREATE_" + table.name.upcase + "_TABLE);\n"
    end
end

File.write("android/utils/AppSQLiteHelper.java", AndroidAppSQLiteHelperTemplate.build(android_package, sqlite_hel_tab_cri, sqlite_hel_tab_cmd))

puts "It is all ok!"