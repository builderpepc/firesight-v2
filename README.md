# FireSight

Voice automation for fire department pre-incident inspections.

FireSight is a Flutter app for capturing inspection observations by voice, attaching photos, saving
inspection sessions locally, and exporting reports. The app is designed for mobile use with online
Gemini support and offline fallbacks.

## The Problem We Solve

Fire departments - the real firefighters themselves, not (just) city officials - have to spend countless hours every year performing inspections on buildings called pre-incident surveys. The purpose of these inspections is to assess risk and strategize for potential emergencies. For high-risk buildings like hospitals or schools, these inspections can happen multiple times per year. As part of these inspections, firefighters need to record countless data points in outdated, clunky web forms or even on paper. Moreover, sometimes the sites are remote or shielded from internet connection.

We spoke to real industry professionals and firefighters at departments like FDNY and Colonia for feedback and insights. There's a real need here, and we built a better solution with the technology available to us today for a better tomorrow for global fire resilience.

## How Our Project Works

Rather than making firefighters meticulously type pages of notes into a phone or tablet, FireSight lets the inspector simply speak out loud about what they're looking at. Using AI glasses (e.g. Meta Ray-Bans), the agent can capture pictures to attach to the inspector's comments and make further observations based on the contents. The inspector can also ask the agent questions about what's been documented, what's missing, what existing records show, etc. When the inspection is done, the firefighter can export a PDF report with a single tap.

Moreover, firefighters need to make detailed observations about every nook and cranny, including places like basements, elevators, or electrical rooms that might not have great internet or cell signal. As such, we've built in an offline AI fallback. Higher-powered AI operations wait for an internet connection, while regular observations and Q&A are supported locally.

# Technical details

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
