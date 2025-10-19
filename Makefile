TITLE = Maintenance tasks for sed.sf.net
HOMEPAGE = https://sed.sourceforge.io
SOURCE = https://github.com/aureliojargas/sed.sf.net
SCRIPTSHTML = $(foreach s,$(wildcard local/scripts/*.sed),$(s).html)
# for the 'browse' target
BINDADDR = 127.0.0.1
PORT = 8080
LOCALURL = http://$(BINDADDR):$(PORT)
PIDFILE = serve.pid

help:  # (default) prints this help
	@sed -f local/scripts/makehelp.sed $(firstword $(MAKEFILE_LIST))

all: site
site: index.html index2html.sed.html $(SCRIPTSHTML)  # (alias: all) updates index and all colorized scripts

index: index.html # updates the index.html file

index.html: index.sed index2html.sed
	sed -f index2html.sed $< > $@

# FIXME: because some scripts are "skipped" dependent targets (such as
# 'index.html') will run unconditionally, since there is no file on the
# filesystem whose timestamp can be checked :/
%.sed.html: %.sed
	./htmlize.sh $<

check: linkchecker.csv  # checks integrity of site links (try EXTERN=1)
	@echo
	# cached results from '$<'; run 'make check -B' to regenerate
	# urlname (1), parentname (2), result (4), url, line, column, name (8-11)
	@cut -d\; -f 1,2,4,8-11 $< | column -ts\;
	@if [ -s $< ]; then echo; exit 1; fi

# linkchecker's "csv" output is actually semi-delimited, but for the sake of
# being able to double-click to open, keep the '.csv' extension
linkchecker.csv: PORT = 8081
linkchecker.csv:
	$(MAKE) serve PORT=$(PORT) BG=1
	sleep 1
	@echo
	-linkchecker$(if $(EXTERN), --check-extern) --output=none --file-output=csv/utf8/$@ $(LOCALURL)
	-cat $(PIDFILE) | xargs kill; rm $(PIDFILE)
	# remove comments in header and footer
	sed '/^#/d' $@ > $@.uncommented && mv $@.uncommented $@

DEPLOYUSER = aureliojargas,sed
DEPLOYHOST = web.sourceforge.net
DEPLOYPATH = /home/groups/s/se/sed/htdocs
DRYRUN = 1
deploy:  # deploys the site to sf.net (try DRYRUN=1)
	rsync$(if $(DRYRUN), --dry-run --itemize-changes) --verbose --archive \
		--update --compress \
		--exclude .git \
		--exclude .gitignore \
		--exclude README.md \
		. \
		$(DEPLOYUSER)@$(DEPLOYHOST):$(DEPLOYPATH)

s: serve
serve:  # (alias: s) serves the site on a local port (try BACKGROUND=1)
ifneq ($(BG)$(BACKGROUND)$(DETACH),)
	@echo
	# hint: you can monitor requests with 'tail -f nohup.out' in another terminal
	nohup python -m http.server --bind $(BINDADDR) $(PORT) 2>&1 & echo $$! > $(PIDFILE) &
else
	python -m http.server --bind $(BINDADDR) $(PORT)
endif

b: browse
browse:  # (alias: b) serves, then open local site in a web browser
	{ sleep 1; python -m webbrowser -t $(LOCALURL); } &
	-$(MAKE) serve &>/dev/null

clean:  # cleans up intermediate files
	# remove the PID file for the server, *if* not running
	-if [ -f "$(PIDFILE)" ] && ! cat $(PIDFILE) | xargs ps -p >/dev/null 2>&1; then \
		cat $(PIDFILE) | xargs kill; \
	fi
	-rm $(PIDFILE) nohup.out

reallyclean: clean  # does 'make clean' plus removes linkchecker outputs
	-rm linkchecker*

