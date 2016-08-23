module AndroidModelTemplate
    def self.build(class_name, package, attributes, get_and_set)
        res = ""
        res += "package " + package + ".models;\n\n"

        res += "import java.util.Date;\n\n"

        res += "public class " + class_name + " {\n"
        res += "    /**\n"
        res += "     *\n"
        res += "     */\n\n"

        res +=      attributes

        res +=      get_and_set

        res += "}\n"

        return res
    end
end