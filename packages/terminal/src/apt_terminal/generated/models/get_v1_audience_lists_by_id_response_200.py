from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.list_stats import ListStats


T = TypeVar("T", bound="GetV1AudienceListsByIdResponse200")


@_attrs_define
class GetV1AudienceListsByIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        created_by (None | str):
        author_kind (None | str):
        author_id (None | str):
        name (str):
        slug (str):
        description (None | str):
        public_key (str):
        status (str):
        welcome_template_id (None | str):
        welcome_back_template_id (None | str):
        from_name (None | str):
        is_deleted (bool):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['audience.list'] | Unset):
        stats (ListStats | Unset):
    """

    id: str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    created_by: None | str
    author_kind: None | str
    author_id: None | str
    name: str
    slug: str
    description: None | str
    public_key: str
    status: str
    welcome_template_id: None | str
    welcome_back_template_id: None | str
    from_name: None | str
    is_deleted: bool
    created: int
    updated: int
    object_: Literal["audience.list"] | Unset = UNSET
    stats: ListStats | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        created_by: None | str
        created_by = self.created_by

        author_kind: None | str
        author_kind = self.author_kind

        author_id: None | str
        author_id = self.author_id

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

        created = self.created

        updated = self.updated

        object_ = self.object_

        stats: dict[str, Any] | Unset = UNSET
        if not isinstance(self.stats, Unset):
            stats = self.stats.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "created_by": created_by,
                "author_kind": author_kind,
                "author_id": author_id,
                "name": name,
                "slug": slug,
                "description": description,
                "public_key": public_key,
                "status": status,
                "welcome_template_id": welcome_template_id,
                "welcome_back_template_id": welcome_back_template_id,
                "from_name": from_name,
                "is_deleted": is_deleted,
                "created": created,
                "updated": updated,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_
        if stats is not UNSET:
            field_dict["stats"] = stats

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.list_stats import ListStats

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        def _parse_created_by(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        created_by = _parse_created_by(d.pop("created_by"))

        def _parse_author_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_kind = _parse_author_kind(d.pop("author_kind"))

        def _parse_author_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_id = _parse_author_id(d.pop("author_id"))

        name = d.pop("name")

        slug = d.pop("slug")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        public_key = d.pop("public_key")

        status = d.pop("status")

        def _parse_welcome_template_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        welcome_template_id = _parse_welcome_template_id(d.pop("welcome_template_id"))

        def _parse_welcome_back_template_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        welcome_back_template_id = _parse_welcome_back_template_id(
            d.pop("welcome_back_template_id")
        )

        def _parse_from_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        from_name = _parse_from_name(d.pop("from_name"))

        is_deleted = d.pop("is_deleted")

        created = d.pop("created")

        updated = d.pop("updated")

        object_ = cast(Literal["audience.list"] | Unset, d.pop("object", UNSET))
        if object_ != "audience.list" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'audience.list', got '{object_}'")

        _stats = d.pop("stats", UNSET)
        stats: ListStats | Unset
        if isinstance(_stats, Unset):
            stats = UNSET
        else:
            stats = ListStats.from_dict(_stats)

        get_v1_audience_lists_by_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            created_by=created_by,
            author_kind=author_kind,
            author_id=author_id,
            name=name,
            slug=slug,
            description=description,
            public_key=public_key,
            status=status,
            welcome_template_id=welcome_template_id,
            welcome_back_template_id=welcome_back_template_id,
            from_name=from_name,
            is_deleted=is_deleted,
            created=created,
            updated=updated,
            object_=object_,
            stats=stats,
        )

        get_v1_audience_lists_by_id_response_200.additional_properties = d
        return get_v1_audience_lists_by_id_response_200

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
