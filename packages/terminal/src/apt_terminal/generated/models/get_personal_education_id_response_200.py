from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetPersonalEducationIdResponse200")


@_attrs_define
class GetPersonalEducationIdResponse200:
    """
    Attributes:
        id (str):
        customer_id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        institution (str):
        degree (str):
        field_of_study (str):
        start_date (str):
        end_date (None | str):
        location (str):
        description (str):
        created_at (str):
        updated_at (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    customer_id: str
    deleted_at: None | str
    ecosystem_id: str
    institution: str
    degree: str
    field_of_study: str
    start_date: str
    end_date: None | str
    location: str
    description: str
    created_at: str
    updated_at: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        customer_id = self.customer_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        ecosystem_id = self.ecosystem_id

        institution = self.institution

        degree = self.degree

        field_of_study = self.field_of_study

        start_date = self.start_date

        end_date: None | str
        end_date = self.end_date

        location = self.location

        description = self.description

        created_at = self.created_at

        updated_at = self.updated_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "customerId": customer_id,
                "deletedAt": deleted_at,
                "ecosystemId": ecosystem_id,
                "institution": institution,
                "degree": degree,
                "fieldOfStudy": field_of_study,
                "startDate": start_date,
                "endDate": end_date,
                "location": location,
                "description": description,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "syncVersion": sync_version,
                "syncStampedAt": sync_stamped_at,
                "syncTxid": sync_txid,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        customer_id = d.pop("customerId")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        ecosystem_id = d.pop("ecosystemId")

        institution = d.pop("institution")

        degree = d.pop("degree")

        field_of_study = d.pop("fieldOfStudy")

        start_date = d.pop("startDate")

        def _parse_end_date(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        end_date = _parse_end_date(d.pop("endDate"))

        location = d.pop("location")

        description = d.pop("description")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        get_personal_education_id_response_200 = cls(
            id=id,
            customer_id=customer_id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            institution=institution,
            degree=degree,
            field_of_study=field_of_study,
            start_date=start_date,
            end_date=end_date,
            location=location,
            description=description,
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return get_personal_education_id_response_200
