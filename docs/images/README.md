# Images

`hero.png` (1600×640 base, rendered at 1.5×) sits at the top of the README and is the banner on the
tool page at simonvedder.com/tools/app-lifecycle-analyzer. It is rendered from `hero.source.html`
next to it, so a change is a text edit and a re-render, not a design tool session.

```bash
cd docs/images
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu --hide-scrollbars \
  --force-device-scale-factor=1.5 --window-size=1600,640 --screenshot=hero.png "file://$PWD/hero.source.html"
```

`report.png` is a screenshot of `../sample-report.html`, which is built from synthetic app
registrations — no tenant was read to produce it:

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu --hide-scrollbars \
  --force-device-scale-factor=1.5 --window-size=1600,1000 --screenshot=docs/images/report.png "file://$PWD/docs/sample-report.html"
```

Both files are copied into the tools site as `app-lifecycle-analyzer-hero.png` and
`app-lifecycle-analyzer-report.png`; keep them in step.
