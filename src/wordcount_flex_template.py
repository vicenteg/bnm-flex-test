import argparse
import logging
import re
from apache_beam import Pipeline, PTransform, DoFn, ParDo, CombinePerKey, Map
from apache_beam.io import ReadFromText, WriteToText
from apache_beam.options.pipeline_options import PipelineOptions, SetupOptions

class WordCountOptions(PipelineOptions):
    @classmethod
    def _add_argparse_args(cls, parser):
        parser.add_argument(
            "--input_file_pattern",
            help="GCS file pattern to read from (e.g., gs://your-bucket/input/*.txt)",
        )
        parser.add_argument(
            "--output_file",
            help="GCS file to write output to (e.g., gs://your-bucket/output/word_counts.txt)",
        )


class ExtractWordsFn(DoFn):
    def process(self, element):
        return re.findall(r'[\w\']+', element, re.UNICODE)


class CountWords(PTransform):
    def expand(self, pcoll):
        return (
            pcoll
            | "ExtractWords" >> ParDo(ExtractWordsFn())
            | "PairWithOne" >> Map(lambda x: (x, 1))
            | "GroupAndSum" >> CombinePerKey(sum)
            | "FormatOutput" >> ParDo(lambda word_count: f"{word_count[0]}: {word_count[1]}")
        )


def run(argv=None, save_main_session=True):
    parser = argparse.ArgumentParser()
    known_args, pipeline_args = parser.parse_known_args(argv)

    pipeline_options = PipelineOptions(pipeline_args)
    pipeline_options.view_as(SetupOptions).save_main_session = save_main_session
    word_count_options = pipeline_options.view_as(WordCountOptions)

    with Pipeline(options=pipeline_options) as p:
        (
            p
            | "ReadFromGCS" >> ReadFromText(word_count_options.input_file_pattern)
            | "CountWords" >> CountWords()
            | "WriteToGCS" >> WriteToText(word_count_options.output_file)
        )


if __name__ == "__main__":
    logging.getLogger().setLevel(logging.INFO)
    run()
