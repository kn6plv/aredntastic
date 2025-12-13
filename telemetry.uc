import * as parse from "parse";

parse.registerProto(
    "telemetry", 67,
    {
        "1": "fixed32 time",
        "2": "proto device_metrics device_metrics",
        "3": "proto environment_metrics environment_metrics",
        "4": "proto unknown air_quality_metrics",
        "5": "proto power_metrics power_metrics",
        "6": "proto unknown local_stats",
        "7": "proto unknown health_metrics",
        "8": "proto unknown host_metrics"
    }
);
