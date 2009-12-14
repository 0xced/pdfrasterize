#import "SimpleApp.h"

@implementation SimpleApp

- (void) application: (DDCliApplication *) app
    willParseOptions: (DDGetoptLongParser *) optionsParser;
{
    [optionsParser setGetoptLongOnly: YES];
    DDGetoptOption optionTable[] = 
    {
        // Long         Short   Argument options
        {@"output",     'o',    DDGetoptRequiredArgument},
        {@"help",       'h',    DDGetoptNoArgument},
        {nil,           0,      0},
    };
    [optionsParser addOptionsFromTable: optionTable];
}

- (int) application: (DDCliApplication *) app
   runWithArguments: (NSArray *) arguments;
{
    ddprintf(@"Output: %@, help: %d\n", _output, _help);
    ddprintf(@"Arguments: %@\n", arguments);
    return EXIT_SUCCESS;
}

@end
