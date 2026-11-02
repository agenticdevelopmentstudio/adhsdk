from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="PutAudienceListsIdResponse200")


@_attrs_define
class PutAudienceListsIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        created_by (None | str):
        name (str):
        slug (str):
        description (None | str):
        public_key (str):
        status (str):
        welcome_template_id (None | str):
        welcome_back_template_id (None | str):
        from_name (None | str):
        is_deleted (bool):
        created_at (str):
        updated_at (str):
    """

    id: str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    created_by: None | str
    name: str
    slug: str
    description: None | str
    public_key: str
    status: str
    welcome_template_id: None | str
    welcome_back_template_id: None | str
    from_name: None | str
    is_deleted: bool
    created_at: str
    updated_at: str

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        created_by: None | str
        created_by = self.created_by

        name = self.name

        slug = self.slug

        description: None | str
        description = self.description

        public_key = self.public_key

        status = self.status

        welcome_template_id: None | str
        welcome_template_id = self.welcome_template_id

        welcome_back_template_id: None | str
        welcome_back_template_id = self.welcome_back_template_id

        from_name: None | str
        from_name = self.from_name

        is_deleted = self.is_deleted

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "createdBy": created_by,
                "name": name,
                "slug": slug,
                "description": description,
                "publicKey": public_key,
                "status": status,
                "welcomeTemplateId": welcome_template_id,
                "welcomeBackTemplateId": welcome_back_template_id,
                "fromName": from_name,
                "isDeleted": is_deleted,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        def _parse_created_by(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        created_by = _parse_created_by(d.pop("createdBy"))

        name = d.pop("name")

        slug = d.pop("slug")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        public_key = d.pop("publicKey")

        status = d.pop("status")

        def _parse_welcome_template_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        welcome_template_id = _parse_welcome_template_id(d.pop("welcomeTemplateId"))

        def _parse_welcome_back_template_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        welcome_back_template_id = _parse_welcome_back_template_id(d.pop("welcomeBackTemplateId"))

        def _parse_from_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        from_name = _parse_from_name(d.pop("fromName"))

        is_deleted = d.pop("isDeleted")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        put_audience_lists_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            created_by=created_by,
            name=name,
            slug=slug,
            description=description,
            public_key=public_key,
            status=status,
            welcome_template_id=welcome_template_id,
            welcome_back_template_id=welcome_back_template_id,
            from_name=from_name,
            is_deleted=is_deleted,
            created_at=created_at,
            updated_at=updated_at,
        )

        return put_audience_lists_id_response_200
