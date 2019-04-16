
/// adapted from https://gist.github.com/blainerothrock/efda6e12fe10792c99c990f8ff3daeba

/*
 gen.swift is a direct port of cfdrake's helloevolve.py from Python 2.7 to Swift 3
 -------------------- https://gist.github.com/cfdrake/973505 ---------------------
 gen.swift implements a genetic algorithm that starts with a base
 population of randomly generated strings, iterates over a certain number of
 generations while implementing 'natural selection', and prints out the most fit
 string.
 The parameters of the simulation can be changed by modifying one of the many
 global variables. To change the "most fit" string, modify OPTIMAL. POP_SIZE
 controls the size of each generation, and GENERATIONS is the amount of
 generations that the simulation will loop through before returning the fittest
 string.
 This program subject to the terms of The MIT License listed below.
 ----------------------------------------------------------------------------------
 Copyright (c) 2016 Blaine Rothrock
 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in the
 Software without restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
 Software, and to permit persons to whom the Software is furnished to do so, subject
 to the following conditions:
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 """
 */
/*
 --- CHANGELOG ---
 
 - 11/11/16: updated fittest loop based on suggestions from @RubenSandwich
 & @RyanPossible
 - 11/11/16: simpilfied the weighted calculation based on suggestion from @nielsbot
 - 11/11/16: completed did away with string manipulation, to only use [UInt] base
 on fork from @dwaite: https://gist.github.com/dwaite/6f26c970170e4d113bf5bfa3316e2eff
 *huge runtime improvement*
 - 11/15/16: mutate function optimization from @dwaite
 */
import Foundation

// HELPERS

/*
 String extension to convert a string to ascii value
 */
extension String {
    var asciiArray: [UInt8] {
        return unicodeScalars.filter{$0.isASCII}.map{UInt8($0.value)}
    }
}

/*
 helper function to return a random character string
 */
func randomChar() -> UInt8 {
    let letters : [UInt8] = "012345".asciiArray
    let len = UInt32(letters.count-1)
    let rand = Int(arc4random_uniform(len))
    return letters[rand]
}

// END HELPERS

var GENETIC_ALGORITHM_DNA_SIZE = 50
var GENETIC_ALGORITHM_VERBOSE_LOGGING = true
let POP_SIZE = 50
var GENETIC_ALGORITHM_GENERATIONS = 100
let MUTATION_CHANCE = 100

public var GENETIC_ALGORITHM_FITNESS_FUNCTION: (([Int]) -> Double)!


func calculateFitness(dna:[UInt8]) -> Double {
    let integers = dna.map { Int($0) - 48 }
    return GENETIC_ALGORITHM_FITNESS_FUNCTION(integers)
}



/*
 randomly mutate the string
 */
func mutate(dna:[UInt8], mutationChance:Int, dnaSize:Int) -> [UInt8] {
    var outputDna = dna
    for i in 0..<dnaSize {
        let rand = Int(arc4random_uniform(UInt32(mutationChance)))
        if rand == 1 {
            outputDna[i] = randomChar()
        }
    }
    return outputDna
}

/*
 combine two parents to create an offspring
 parent = xy & yx, offspring = xx, yy
 */
func crossover(dna1:[UInt8], dna2:[UInt8], dnaSize:Int) -> (dna1:[UInt8], dna2:[UInt8]) {
    let pos = Int(arc4random_uniform(UInt32(dnaSize-1)))
    let dna1Index1 = dna1.index(dna1.startIndex, offsetBy: pos)
    let dna2Index1 = dna2.index(dna2.startIndex, offsetBy: pos)
    return (
        [UInt8](dna1.prefix(upTo: dna1Index1) + dna2.suffix(from: dna2Index1)),
        [UInt8](dna2.prefix(upTo: dna2Index1) + dna1.suffix(from: dna1Index1))
    )
}

/*
 returns a random population, used to start the evolution
 */
func randomPopulation(populationSize: Int, dnaSize: Int) -> [[UInt8]] {
    let letters : [UInt8] = "012345".asciiArray
    let len = UInt32(letters.count)
    var pop = [[UInt8]]()
    for _ in 0..<populationSize {
        var dna = [UInt8]()
        for _ in 0..<dnaSize {
            let rand = arc4random_uniform(len)
            let nextChar = letters[Int(rand)]
            dna.append(nextChar)
        }
        pop.append(dna)
    }
    return pop
}

/*
 function to return random canidate of a population randomally, but weight on fitness.
 */
func weightedChoice(items:[(item:[UInt8], weight:Double)]) -> (item:[UInt8], weight:Double) {
    let topChoices = items
        .sorted(by: { $0.weight > $1.weight })
        .prefix(upTo: POP_SIZE/(10...20).randomElement()!)
    
    return topChoices.randomElement()!
}

func runGeneticAlgorithm() -> [Int] {
    // generate the starting random population
    var population = randomPopulation(populationSize: POP_SIZE, dnaSize: GENETIC_ALGORITHM_DNA_SIZE)
    
    var fittest = [UInt8]()
    var maxFitnessSoFar = 0.0
    
    for generation in 0...GENETIC_ALGORITHM_GENERATIONS {
        //print("Generation \(generation) with random sample: \(String(bytes: population[0], encoding:.ascii)!)")
        
        if GENETIC_ALGORITHM_VERBOSE_LOGGING {
            print("Generation \(generation) with most fit: \(String(bytes: fittest, encoding:.ascii)!) (score \(calculateFitness(dna: fittest)))")
        }
        
        let weightedPopulation = population.map { individual -> ([UInt8], Double) in
            return (individual, calculateFitness(dna: individual))
        }

        population = []
        // create a new generation using the individuals in the origional population
        for _ in 0...POP_SIZE/2 {
            let ind1 = weightedChoice(items: weightedPopulation)
            let ind2 = weightedChoice(items: weightedPopulation)
            let offspring = crossover(dna1: ind1.item, dna2: ind2.item, dnaSize: GENETIC_ALGORITHM_DNA_SIZE)
            // append to the population and mutate
            population.append(mutate(dna: offspring.dna1, mutationChance: MUTATION_CHANCE, dnaSize: GENETIC_ALGORITHM_DNA_SIZE))
            population.append(mutate(dna: offspring.dna2, mutationChance: MUTATION_CHANCE, dnaSize: GENETIC_ALGORITHM_DNA_SIZE))
        }
        
        // parse the population for the fittest string
        for (individual, fitness) in weightedPopulation {
            if fitness > maxFitnessSoFar {
                fittest = individual
                maxFitnessSoFar = fitness
            }
        }
    }
    
    return fittest.map { Int($0) - 48 }
}
