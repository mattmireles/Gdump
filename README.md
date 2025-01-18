# Gdump ☁️💩

Are you having Gemini API problems? Of course you are. That's why you're here.

So Gemini's been secretly storing your files for 48 hours. And it has a 20GB limit. Which it doesn't tell you about. Until your API calls mysteriously stop working and you spend six hours of your life that you'll never get back trying to figure out why. You just realized this. 

Don't worry. We've all been there. That's why Gdump exists.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/mattmireles/gdump/main/install_gdump.sh | bash
```

The installer will walk you through adding your Google Cloud Project(s). Yes, you need API keys. No, we can't avoid it. Here's where to find them:

Get your API key(s) from either:

- [Google AI Studio](https://makersuite.google.com/app/apikey) (easiest)
- [Google Cloud Console](https://console.cloud.google.com) (if you need more control)

## What it Does

Gdump finds and deletes all those temporary files Gemini has been hoarding. One command, no fuss:

```bash
gdump
```

Run it manually whenever you want, or set up automatic dumps to never think about it again.

## Automatic Dumps

Because who wants to think about this more than once? Set it and forget it:

```bash
gdump --schedule
```

Choose from:
- Hourly
- Daily 
- Custom schedule 

Your dumps will run silently in the background, with logs saved to `~/.gdump/gdump.log`.

Need to check your schedule?
```bash
gdump --show-schedule
```

Want to go back to manual mode?
```bash
gdump --remove-schedule
```

## Features

- Cleans up files across multiple projects
- Handles pagination (because of course you have more than 100 files)
- Shows progress (so you know it's doing something)
- Stores config securely (we're not animals)
- Project management:
  - `gdump --edit` to add/remove/edit projects
  - Fat-finger protection included

## Common Commands

```bash
# Run a manual dump
gdump

# Add or edit your projects
gdump --edit

# Set up automatic dumps
gdump --schedule

# Check your current schedule
gdump --show-schedule

# Stop automatic dumps
gdump --remove-schedule

# Show all commands
gdump --help

# Check version
gdump --version
```

## Contributing

Found a bug? Of course you did. Please file an issue or send a PR.

## License

MIT

## Author

Matt Mireles ([@mattmireles](https://twitter.com/mattmireles))

---

If you found this useful, maybe give it a star? It won't fix Gemini's file limit, but it might make me feel better about writing this.
