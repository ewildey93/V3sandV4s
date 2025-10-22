

sswids::connect_to_sswidb(db_version = 'PROD')

PartnerV4UpdateFirmware <- DBI::dbGetQuery(conn, "SELECT DISTINCT
    g83100.sswi_photo.camera_firmware_text,
    g83100.sswi_photo.upload_batch_seq_no,
    g83100.sswi_camera.dnr_inventory_id,
    g83100.sswi_camera.camera_seq_no AS camera_seq_no1,
    g83100.sswi_cam_part_grid_xref.partner_seq_no,
    g83100.sswi_partner.first_name,
    g83100.sswi_partner.last_name,
    g83100.sswi_partner.partner_comment_text
FROM
         g83100.sswi_photo
    INNER JOIN g83100.sswi_camera ON g83100.sswi_photo.camera_seq_no = g83100.sswi_camera.camera_seq_no
    INNER JOIN g83100.sswi_cam_part_grid_xref ON g83100.sswi_camera.camera_seq_no = g83100.sswi_cam_part_grid_xref.camera_seq_no
    INNER JOIN g83100.sswi_partner ON g83100.sswi_cam_part_grid_xref.partner_seq_no = g83100.sswi_partner.partner_seq_no
WHERE
    g83100.sswi_photo.camera_firmware_text = 'G5C2YL2006024'")

unique(PartnerV4UpdateFirmware$PARTNER_COMMENT_TEXT)


PhotosV4UpdateFirmware <- DBI::dbGetQuery(conn, "SELECT 
    g83100.sswi_photo.camera_firmware_text,
    g83100.sswi_photo.upload_batch_seq_no,
    g83100.sswi_photo.trigger_seq_no,
    g83100.sswi_photo.photo_seq_no,
    g83100.sswi_photo.camera_seq_no,
    g83100.sswi_photo.camera_location_seq_no
FROM
         g83100.sswi_photo
WHERE
    g83100.sswi_photo.camera_firmware_text = 'G5C2YL2006024'")
table(PhotosV4UpdateFirmware$UPLOAD_BATCH_SEQ_NO)
table(PhotosV4UpdateFirmware$CAMERA_SEQ_NO)
table(PhotosV4UpdateFirmware$CAMERA_LOCATION_SEQ_NO)




DTQC <- DBI::dbGetQuery(conn,"SELECT DISTINCT
g83100.sswi_photo.camera_firmware_text,
g83100.sswi_photo.upload_batch_seq_no,
g83100.sswi_photo.camera_seq_no,
g83100.sswi_batch.start_active_date,
g83100.sswi_batch.end_active_date,
g83100.sswi_dtqc_error.dtqc_error_code,
g83100.sswi_dtqc_error.corr_batch_start_date,
g83100.sswi_dtqc_error.corr_batch_end_date,
g83100.sswi_dtqc_error.comment_text
FROM
g83100.sswi_photo
INNER JOIN g83100.sswi_batch ON g83100.sswi_photo.upload_batch_seq_no = g83100.sswi_batch.batch_seq_no
INNER JOIN g83100.sswi_dtqc_error ON g83100.sswi_batch.batch_seq_no = g83100.sswi_dtqc_error.batch_seq_no
WHERE
g83100.sswi_photo.camera_firmware_text = 'G5C2YL2006024'")
