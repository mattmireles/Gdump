# Gdump ☁️💩

Are you having Gemini API problems? Of course you are. That's why you're here.

So Gemini's been secretly storing your files. And it has a 20GB limit. Which it doesn't tell you about. Until your API calls mysteriously stop working and you spend six hours of your life that you'll never get back trying to figure out why.

Don't worry. We've all been there. That's why Gdump exists.

## What it Does

Gdump finds and deletes all those temporary files Gemini has been hoarding. One command, no fuss:

```bash
gdump
```

That's it. That's the whole thing.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/mattmireles/gdump/main/install_gdump.sh | bash
```

The installer will walk you through a brief configuration where you'll enter your Google Cloud project(s) details. Yes, you need API keys. No, we can't avoid it. Here's where to find them:

Get your API key(s) from either:

- [Google AI Studio](https://makersuite.google.com/app/apikey) (easiest)
- [Google Cloud Console](https://console.cloud.google.com) (if you need more control)

Need to reconfigure later? Just run:
```bash
gdump --configure
```

## Features

- Cleans up files across multiple projects
- Handles pagination (because of course you have more than 100 files)
- Shows progress (so you know it's doing something)
- Stores config securely (we're not animals)

## Contributing

Found a bug? Of course you did. Please file an issue or send a PR.

## License

MIT

## Author

Matt Mireles ([@mattmireles](https://twitter.com/mattmireles))

---

If you found this useful, maybe give it a star? It won't fix Gemini's file limit, but it might make me feel better about writing this.
