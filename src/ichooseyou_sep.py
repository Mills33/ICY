

import pandas as pd
import numpy as np
import csv

def format_pmx_list(data):
    All_living_founder_list = []
    Founders = []
    Founder_contrib = []
    founder_list = data["MyFounders"]
    for every_founder in founder_list:
        remove_format = every_founder.replace("|", ",").strip("[]")
        formatted_founder_list = remove_format.split(",")
        Founders.append(formatted_founder_list)
        for every_founder in formatted_founder_list:
            if every_founder not in All_living_founder_list:
                All_living_founder_list.append(every_founder)
    founder_contrib_list = data["MyFounderContribs"]
    for every_contrib in founder_contrib_list:
        remove_format_contrib = every_contrib.replace("|", ",").strip("[]")
        formatted_contrib_list = remove_format_contrib.split(",")
        Founder_contrib.append(formatted_contrib_list)
    data["MyFounders"] = Founders
    data["MyFounderContribs"] = Founder_contrib
    All_living_founder_list.append('Unk')
    return(All_living_founder_list, data)

def count_founders(data):
    Number_founders = []
    for founder_list in data["MyFounders"]:
        Number_founders.append(len(founder_list))
    data["Number of founders"] = Number_founders
    return(data)

def convert_founder_percentage(data):
    myfound_list = data["MyFounders"]
    mycontrib_list = data["MyFounderContribs"] # the proportion each tributes to that individual
    unk_proportion = []
    unk_founder = []
    percentage_contrib = []
    founder_genome = []
    for x in range(0,len(myfound_list)):
        individual = mycontrib_list[x] # take list of proportions for that individual
        percentage = [float(prop) * 100 for prop in individual]
        percentage = [round(value,2) for value in percentage] # round each percentage in list
        fi = founder_genome_equiv(individual)
        founder_genome.append(fi)
        if sum(percentage) >= 100:
            percentage_contrib.append(percentage) # append list of percentages to percentage contrib
            found_list = myfound_list[x] # the list of founders is the list of founders for that individual
            unk_founder.append(found_list) # add list to unk.founder ( this is just to make the same variable name for later)
            unk_proportion.append(individual)# see comment above
            #found_list = ", ".join(found_list)
        else:
            unk_contrib = 100 - sum(percentage) # unk contribution is equal to 100 - sum percentages
            unk_prop = unk_contrib/100 # creates unkown proportion (needed for fi)
            individual.append(unk_prop) # add unkwon prop to list
            unk_proportion.append(individual) # create list of list length number individuals
            percentage.append(round(float(unk_contrib), 3)) # append this number to percentages as a rounded float
            percentage_contrib.append(percentage)  # append list of percentages to percentage contrib
            found_list = myfound_list[x] # the list of founders is the list of founders for that individual
            found_list.append("Unk")# append Unk to list of founders
            unk_founder.append(found_list)
            #found_list = ", ".join(found_list)
    data["MyFounderContribs"] = unk_proportion
    data["FounderContribution(%)"] = percentage_contrib # new column percentage contribution = percentage contribtution
    data["MyFounders"] = unk_founder # new column MyFounders = unk founders
    data["Fe"] = founder_genome
    data = data.round(3)# round all data
    return(data)

def create_dataset(data_frame):
    empty_array = ([['UniqueID'],["FounderContribution(%)"], ['Founder']])
    for index, row in data_frame.iterrows():
        ID = []
        Perc_contrib = []
        Founder_name = []
        Ind, Percent, Founder = (row['UniqueID'], row["FounderContribution(%)"], row['MyFounders'])
        [Perc_contrib.append(x) for x in Percent]
        [Founder_name.append(y) for y in Founder]
        [ID.append(Ind) for x in Percent]
        stacked = np.vstack((ID, Perc_contrib, Founder_name))
        empty_array = np.hstack((empty_array, stacked))
    df1 = pd.DataFrame(empty_array, index = ['UniqueID',"FounderContribution(%)",'Founder'])
    df = df1.transpose()
    df = df.drop(df.index[0])
    return(df)

def founder_genome_equiv(proportions):
    values_squared =  [float(value)**2 for value in proportions]
    sum_values = sum(values_squared)
    fe = 1/sum_values
    fe = round(fe, 3)
    return(fe)

def format_matrix_from_studbook(csv_file):
    column = []
    kinship_matrix = pd.read_csv(csv_file)
    kinship_matrix.drop(index = 0, inplace = True)
    kinship_matrix.drop(kinship_matrix.columns[1], axis = 1, inplace = True)
    kinship_matrix['UniqueID'] = kinship_matrix['UniqueID'].str.strip()
    kinship_matrix.set_index('UniqueID', inplace = True)
    columns = list(kinship_matrix.columns.values)
    for name in columns:
        name = name.strip()
        name = str(name)
        column.append(name)
    kinship_matrix.columns = column
    return(kinship_matrix)

def change_index_to_ID(data):
    new_data = data.set_index('UniqueID', inplace = False)
    new_data.rename(index=str, inplace=True)
    ranked_birds = list(new_data.index.values)
    return(new_data, ranked_birds)

def delete_too_related(data, undesirable_list):
    for bird in undesirable_list:
        if bird in list(data.index.values):
            data.drop(index = bird, inplace = True) # MAKE BOTH STRINGS this is only necessary as unique ID numbers if not we will crash
        else:
            continue
    return(data)


def remove_related_from_kinship_matrix(kinship_matrix, undesirable_list):
    KM = delete_too_related(kinship_matrix, undesirable_list)
    for bird in undesirable_list:
        KM.drop(columns = bird , inplace = True)
    return(KM)


def checking_relatedness(threshold, ID, kinship_matrix):
    delete_individuals = []
    kin_coeff = kinship_matrix.loc[ID]
    column_list = list(kin_coeff)
    for x in range(0, len(kinship_matrix)):
        cell_value = column_list[x]
        value = float(cell_value)
        column_name = kinship_matrix.columns[x]
        if value >= threshold:
            delete_individuals.append(column_name)
    number_unsuitable = len(delete_individuals)
    return(delete_individuals, number_unsuitable)

def chosen_animals(threshold, number_males, number_females, data, kinship_matrix):
    female_counter = 0
    male_counter = 0
    the_chosen_ones = []
    all_data, ranked_birds = change_index_to_ID(data)
    while (female_counter != number_females or male_counter != number_males):
        individual = all_data.index.values[0]
        if all_data.at[individual, 'Sex'] == 'Female':
            if female_counter < number_females:
                undesirable_list, number = checking_relatedness(threshold, individual, kinship_matrix)
                the_chosen_ones.append(individual)
                all_data = delete_too_related(all_data, undesirable_list)
                kinship_matrix = remove_related_from_kinship_matrix(kinship_matrix, undesirable_list)
                female_counter += 1
            else:
                all_data.drop(index = individual, inplace = True) # add exception if bird deleted from data but not kinship if it then is added to an undesirable list thst they try and execute will already have been deleted
        else: #all_data.at[individual,'Sex'] == 'Male'
            if male_counter < number_males:
                undesirable_list, number = checking_relatedness(threshold, individual, kinship_matrix)
                the_chosen_ones.append(individual)
                all_data = delete_too_related(all_data, undesirable_list) # add exception to undesirable if empty
                kinship_matrix = remove_related_from_kinship_matrix(kinship_matrix, undesirable_list)
                male_counter += 1
            else:
                all_data.drop(index = individual, inplace = True)
    ranked_data, ranked_birds = change_index_to_ID(data)
    chosen_ones_tables = ranked_data.loc[the_chosen_ones]
    chosen_ones_tables.reset_index(level=0, inplace=True)
    return(the_chosen_ones, chosen_ones_tables)


def create_data_file(datafile):
        panda = pd.read_csv(datafile, usecols=["UniqueID", "Location", "Sex", "F", "MK", "AgeYears", "MyFounders", "MyFounderContribs", "Alive"])
        all_live_found_list, data = format_pmx_list(panda)
        data.query("Alive == True", inplace = True)
        data.drop(columns = "Alive", inplace = True )
        data = count_founders(data)
        data = convert_founder_percentage(data)
        data = data.sort_values(["Fe", "MK"], ascending=[False, True])
        data['Rank'] = list(range(1, len(data) + 1))
        return(data)

def female_data_format(datafile):
        data = create_data_file(datafile)
        female = data.query("Sex == 'Female'")
        female_data = female.sort_values(["Fe", "MK"], ascending=[False, True])
        return(female_data)

def male_data_format(datafile):
        data = create_data_file(datafile)
        male = data.query("Sex == 'Male'")
        male_data = male.sort_values(["Fe", "MK"], ascending=[False, True])
        return(male_data)

def chosen_ones_tables(datafile, kinship_matrix, threshold, number_males, number_females ):
    data = create_data_file(datafile)
    kinship_matrix = format_matrix_from_studbook(kinship_matrix)
    the_chosen_ones, the_chosen_ones_table= chosen_animals(threshold, number_males, number_females, data, kinship_matrix)
    return(the_chosen_ones_table)
