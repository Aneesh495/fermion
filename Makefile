PYTHON ?= python3

.PHONY: all check test demo bench lint clean help

help:
	@echo "fermion: Fault-Tolerant Second-Quantized Simulation & Topological Anyon Kernel"
	@echo ""
	@echo "Targets:"
	@echo "  all      Validate Q# project compilation and initialize runtime"
	@echo "  check    Run style verification (no em dashes, no forbidden words)"
	@echo "  test     Execute full verification test suite across all subsystems"
	@echo "  demo     Run end-to-end multi-stage quantum demonstration"
	@echo "  bench    Run performance, Trotter scaling, and error threshold benchmarks"
	@echo "  clean    Remove transient artifacts and bytecode caches"

all: check
	$(PYTHON) -c "from qdk import qsharp; qsharp.init(project_root='.'); print('Q# project initialized successfully.')"

check:
	$(PYTHON) tools/verify_style.py

test: check
	$(PYTHON) -m unittest discover -s tests -p "test_*.py" -v

demo: check
	$(PYTHON) -m runtime.cli demo

bench: check
	$(PYTHON) benchmarks/run_benchmarks.py

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.py[cod]" -delete
	find . -type f -name "*.ll" -delete
	find . -type f -name "*.bc" -delete
	rm -rf .pytest_cache .coverage htmlcov
