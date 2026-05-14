# FireSight

Voice automation for fire department pre-incident inspections.

FireSight is a Flutter app for capturing inspection observations by voice, attaching photos, saving
inspection sessions locally, and exporting reports. The app is designed for mobile use with online
Gemini support and offline fallbacks.

## Current MVP Features

- Create and resume local inspection sessions.
- Capture inspection observations as notes and photo-linked floorplan pins.
- Auto-fill a structured FireSight inspection form from saved observations.
- Review and edit auto-filled form fields before export.
- Generate and share an offline PDF report from the structured form and raw observations.

The current form autofill MVP uses a local rule-based engine with heuristic confidence scores. The
autofill service is intentionally behind the `FormAutofillEngine` interface so future Cactus or
Gemini engines can replace or augment the rule-based implementation without changing the form UI or
PDF export path.

## Setup

This project is designed to be set up with the help of a coding agent (e.g. Claude Code). Open the
project in your agent, ask it to set up the project, and it will auto-discover the project context
and setup skill in `.agents/skills/firesight-setup/` and guide you through the full process.
