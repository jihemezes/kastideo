#!/usr/bin/env python3
"""Ajoute la cible de tests UI (captures d'écran) à une copie de project.yml : project-screens.yml.
Le project.yml de production n'est pas modifié."""
import yaml

spec = yaml.safe_load(open("project.yml"))
spec["targets"]["KastideoiOSUITests"] = {
    "type": "bundle.ui-testing",
    "platform": "iOS",
    "deploymentTarget": "17.0",
    "sources": [{"path": "iOS/ScreenshotTests"}],
    "dependencies": [{"target": "KastideoiOS"}],
    "settings": {"base": {
        "GENERATE_INFOPLIST_FILE": "YES",
        "PRODUCT_BUNDLE_IDENTIFIER": "fr.jmezes.kastideo.uitests",
        "SWIFT_VERSION": "5.0",
    }},
}
spec["targets"]["KastideoiOS"].setdefault("scheme", {})["testTargets"] = ["KastideoiOSUITests"]
spec["targets"]["KastideotvOSUITests"] = {
    "type": "bundle.ui-testing",
    "platform": "tvOS",
    "deploymentTarget": "17.0",
    "sources": [{"path": "tvOS/ScreenshotTests"}],
    "dependencies": [{"target": "KastideotvOS"}],
    "settings": {"base": {
        "GENERATE_INFOPLIST_FILE": "YES",
        "PRODUCT_BUNDLE_IDENTIFIER": "fr.jmezes.kastideo.tvuitests",
        "SWIFT_VERSION": "5.0",
    }},
}
spec["targets"]["KastideotvOS"].setdefault("scheme", {})["testTargets"] = ["KastideotvOSUITests"]
yaml.safe_dump(spec, open("project-screens.yml", "w"), allow_unicode=True, sort_keys=False)
print("project-screens.yml écrit")
