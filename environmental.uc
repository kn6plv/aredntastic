import * as parse from "parse";
import * as telemetry from "telemetry";

parse.registerProto(
    "environment_metrics", null,
    {
        "1": "float temperature",
        "2": "float relative_humidity",
        "3": "float barometric_pressure",
        "4": "float gas_resistance",
        "5": "float voltage",
        "6": "float current",
        "7": "uint32 iaq",
        "8": "float distance",
        "9": "float lux",
        "10": "float white_lux",
        "11": "float ir_lux",
        "12": "float uv_lux",
        "13": "uint32 wind_direction",
        "14": "float wind_speed",
        "15": "float weight",
        "16": "float wind_gust",
        "17": "float wind_lull",
        "18": "float radiation",
        "19": "float rainfall_1h",
        "20": "float rainfall_24h",
        "21": "uint32 soil_moisture",
        "22": "float soil_temperature"
    }
);

export function convert(tounit, value)
{
    if (!value) {
        return null;
    }
    const fromunit = value.units;
    let v = value.value;
    switch (tounit) {
        case "C":
            switch(substr(fromunit, -1)) {
                case "F":
                    v = (v - 32) / 1.8;
                    break;
                default:
                    break;
            }
        case "hPA":
            switch (fromunit) {
                case "inHg":
                    v *= 33.86389;
                    break;
                default:
                    break;
            }
        case "m/s":
            switch (fromunit) {
                case "mph":
                    v *= 0.44704;
                    break;
                default:
                    break;
            }
        case "mm/h":
            switch (fromunit) {
                case "in/h":
                    v *= 25.4;
                    break;
                default:
                    break;
            }
        case "mm":
            switch (fromunit) {
                case "in":
                    v *= 25.4;
                    break;
                default:
                    break;
            }
        default:
            break;
    }
    return v;
};
