public with sharing class brCategoryService {

    public static List<brCategoriesCatalogModel> getAllCategoriesForGroup(String dataCategoryName) {

        if(String.isBlank(dataCategoryName)) return new List<brCategoriesCatalogModel>();

        List<DescribeDataCategoryGroupStructureResult> categoryStructRes = Schema.describeDataCategoryGroupStructures(brCategoryServiceSelector.getDataCategoryGroupPairs(dataCategoryName), false);
        DataCategory[] topCategories = categoryStructRes[0].getTopCategories();

        return brCategoryServiceSelector.getChildCategories(topCategories[0], categoryStructRes[0].name);

    }

}