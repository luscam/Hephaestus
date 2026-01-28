return {
    ["Minify"] = {
        LuaVersion = "Lua51";
        VarNamePrefix = "";
        NameGenerator = "Hephaestus";
        PrettyPrint = false;
        Seed = 0;
        SecretKey = "HephaestusDefault";
        Steps = {

        }
    };
    ["Weak"] = {
        LuaVersion = "Lua51";
        VarNamePrefix = "";
        NameGenerator = "Hephaestus";
        PrettyPrint = false;
        Seed = 0;
        SecretKey = "HephaestusDefault";
        Steps = {
            {
                Name = "Vmify";
                Settings = {

                };
            },
            {
                Name = "ConstantArray";
                Settings = {
                    Treshold    = 1;
                    StringsOnly = true;
                }
            },
            {
                Name = "WrapInFunction";
                Settings = {

                }
            },
        }
    };
    ["Vmify"] = {
        LuaVersion = "Lua51";
        VarNamePrefix = "";
        NameGenerator = "Hephaestus";
        PrettyPrint = false;
        Seed = 0;
        SecretKey = "HephaestusDefault";
        Steps = {
            {
                Name = "Vmify";
                Settings = {

                };
            },
        }
    };
    ["Medium"] = {
        LuaVersion = "Lua51";
        VarNamePrefix = "";
        NameGenerator = "Hephaestus";
        PrettyPrint = false;
        Seed = 0;
        SecretKey = "HephaestusDefault";
        Steps = {
            {
                Name = "EncryptStrings";
                Settings = {

                };
            },
            {
                Name = "AntiTamper";
                Settings = {
                    UseDebug = false;
                };
            },
            {
                Name = "Vmify";
                Settings = {

                };
            },
            {
                Name = "ConstantArray";
                Settings = {
                    Treshold    = 1;
                    StringsOnly = true;
                    Shuffle     = true;
                    Rotate      = true;
                    LocalWrapperTreshold = 0;
                }
            },
            {
                Name = "NumbersToExpressions";
                Settings = {

                }
            },
            {
                Name = "WrapInFunction";
                Settings = {

                }
            },
        }
    };
    ["Strong"] = {
        LuaVersion = "Lua51";
        VarNamePrefix = "";
        NameGenerator = "Hephaestus";
        PrettyPrint = false;
        Seed = 0;
        SecretKey = "HephaestusDefault";
        Steps = {
            {
                Name = "Vmify";
                Settings = {

                };
            },
            {
                Name = "EncryptStrings";
                Settings = {

                };
            },
            {
                Name = "AntiTamper";
                Settings = {

                };
            },
            {
                Name = "Vmify";
                Settings = {

                };
            },
            {
                Name = "ConstantArray";
                Settings = {
                    Treshold    = 1;
                    StringsOnly = true;
                    Shuffle     = true;
                    Rotate      = true;
                    LocalWrapperTreshold = 0;
                }
            },
            {
                Name = "NumbersToExpressions";
                Settings = {

                }
            },
            {
                Name = "WrapInFunction";
                Settings = {

                }
            },
        }
    },
}