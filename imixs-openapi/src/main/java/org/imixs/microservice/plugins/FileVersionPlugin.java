package org.imixs.microservice.plugins;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Date;
import java.util.logging.Logger;

import org.imixs.workflow.ItemCollection;
import org.imixs.workflow.WorkflowKernel;
import org.imixs.workflow.FileData;
import org.imixs.workflow.engine.plugins.AbstractPlugin;
import org.imixs.workflow.exceptions.PluginException;

/**
 * Это расширение предназначенно для последовательного версионирования файлов,
 * прикрепляемых к процессу. Считается, что процесс управляет только одним
 * файлом. Новая версия файла прикрепляется в поле 'fileVersion'.
 * 
 * XML фрмат:
 * <item name="fileVersion">
 *   <value xsi:type="xmlItemArray">
 *     <item name="contentType">
 *       <value xsi:type="xs:string">{{ MIME ТИП ФАЙЛА }}</value>
 *     </item>
 *     <item name="content">
 *       <value xsi:type="xs:base64Binary">{{ BASE64 }}</value>
 *     </item>
 *   </value>
 * </item>
 * 
 * После добавления, поле будет очищено, будет добавлена запись в txtFileVersionLog,
 * название последней версии файла будет записано в поле namLastFileVersion.
 * 
 * После применения изменений:
 * <item name="fileVersion">
 *   <value nill="true"/>
 * </item>
 * <item name="namLastFileVersion">
 *   <value xsi:type="xs:string">v{{ НАЗВАНИЕ ВЕРСИИ ФАЙЛА }}</value>
 * </item>
* <item name="txtFileVersionLog">
 *   <value xsi:type="xmlItemArray">
 *     <item name="datcreation">
 *       <value xsi:type="xs:date">{{ ДАТА ДОБАВЛЕНИЯ ВЕРСИИ ФАЙЛА }}</value>
 *     </item>
 *     <item name="namcreator">
 *       <value xsi:type="xs:string">{{ ИМЯ СОЗДАТЕЛЯ }}</value>
 *     </item>
 *     <item name="namversion">
 *       <value xsi:type="xs:string">{{ НАЗВАНИЕ ВЕРСИИ ФАЙЛА }}</value>
 *     </item>
 *   </value>
 *   <value xsi:type="xmlItemArray">
 *     {{ МАССИВ ДАННЫХ ДАЛЕЕ }}
 *   </value>
 * </item>
 * 
 * @author twobrowin
 * @version 1.0
 * 
 */
public class FileVersionPlugin extends AbstractPlugin {

	ItemCollection documentContext;

	private static Logger logger = Logger.getLogger(CommentPlugin.class.getName());
	
	@Override
	public ItemCollection run(ItemCollection adocumentContext, ItemCollection documentActivity) throws PluginException {

		documentContext = adocumentContext;

		/*
		 * Добавление файла: - тип данных содержимого поля - List, сложные типы следует
		 * преобразовывать (.get(0))
		 */
		if (documentContext.hasItem("fileVersion")) {

			Map<String, List> fileVersionMap = (Map<String, List>) documentContext.getItemValue("fileVersion").get(0);
			String fileVersionName = "v1";

			/*
			 * Вычисление названия версии файла
			 */
			if (documentContext.hasItem("namLastFileVersion")) {
				String namLastFileVersion = documentContext.getItemValueString("namLastFileVersion");
				Integer lastFileVersionInt = Integer.parseInt(namLastFileVersion.replaceAll("[\\D]", ""));
				Integer fileVersionInt = lastFileVersionInt + 1;
				fileVersionName = String.format("v%d", fileVersionInt);
			}

			/*
			 * Добавление файла
			 */
			if (fileVersionMap.containsKey("contentType") && fileVersionMap.containsKey("content")) {

				logger.info("Adding new file version");

				String contentType = (String) fileVersionMap.get("contentType").get(0);
				byte[] content = (byte[]) fileVersionMap.get("content").get(0);

				Date datCreation = documentContext.getItemValueDate(WorkflowKernel.LASTEVENTDATE);
				String namCreator = this.getWorkflowService().getUserName();

				/*
				 * Названия полей нижним регистром по требованию Imixs
				 */
				List<Map<String, Object>> fileVersionLog = documentContext.getItemValue("txtFileVersionLog");
				Map<String, Object> attributes = new HashMap<>();
				attributes.put("namversion",  fileVersionName);
				attributes.put("datcreation", datCreation);
				attributes.put("namcreator",  namCreator);
				fileVersionLog.add(0, attributes);

				FileData fileData = new FileData(fileVersionName, content, contentType, null);

				documentContext.replaceItemValue("fileVersion", null);
				documentContext.replaceItemValue("txtFileVersionLog", fileVersionLog);
				documentContext.addFileData(fileData);
				documentContext.replaceItemValue("namLastFileVersion", fileVersionName);

			}
		}
		
		return documentContext;
	}	

}
